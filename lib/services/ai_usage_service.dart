import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/ai_limits_config.dart';

/// Structured response object for AI usage limit checks.
class AIUsageCheckResult {
  final bool allowed;
  final String? errorCode;
  final String message;
  final int currentCount;
  final int limit;

  const AIUsageCheckResult({
    required this.allowed,
    this.errorCode,
    this.message = '',
    this.currentCount = 0,
    this.limit = 0,
  });

  Map<String, dynamic> toJson() => {
        'success': allowed,
        if (errorCode != null) 'errorCode': errorCode,
        'message': message,
        'currentCount': currentCount,
        'limit': limit,
      };
}

/// Custom Exception thrown when daily per-user AI limits are exhausted.
class AIUsageLimitException implements Exception {
  final String message;
  final String errorCode;

  const AIUsageLimitException({
    required this.message,
    this.errorCode = 'AI_DAILY_LIMIT_REACHED',
  });

  @override
  String toString() => message;
}

/// Centralized service enforcing per-user AI usage limits, rate-limiting, and quota tracking.
class AIUsageService {
  static final AIUsageService instance = AIUsageService._internal();
  AIUsageService._internal();

  SupabaseClient get _client => Supabase.instance.client;

  /// In-memory rate limiting map (prevents rapid duplicate clicks within 2 seconds)
  final Map<String, DateTime> _lastRequestTimes = {};

  /// In-memory guest mode usage counter
  final Map<String, int> _guestUsage = {};

  /// Checks and atomically consumes one unit of quota for [operation].
  ///
  /// Obtains the authenticated user's actual user ID directly from the Supabase auth JWT.
  /// Rejects requests when daily limit is reached with code 'AI_DAILY_LIMIT_REACHED'.
  Future<AIUsageCheckResult> checkAndConsumeLimit(String operation) async {
    final user = _client.auth.currentUser;
    final maxLimit = AILimitsConfig.getLimitForOperation(operation);

    // 1. Backend/Client Rate Limiting (Prevent rapid duplicate clicks within 2 seconds)
    final rateKey = '${user?.id ?? "guest"}_$operation';
    final now = DateTime.now();
    if (_lastRequestTimes.containsKey(rateKey)) {
      final elapsedMs = now.difference(_lastRequestTimes[rateKey]!).inMilliseconds;
      if (elapsedMs < 2000) {
        return const AIUsageCheckResult(
          allowed: false,
          errorCode: 'AI_RATE_LIMIT_EXCEEDED',
          message: 'Please wait a moment before sending another request.',
        );
      }
    }
    _lastRequestTimes[rateKey] = now;

    // 2. Unauthenticated / Demo User fallback
    if (user == null) {
      final guestCount = (_guestUsage[operation] ?? 0) + 1;
      if (guestCount > maxLimit) {
        return AIUsageCheckResult(
          allowed: false,
          errorCode: 'AI_DAILY_LIMIT_REACHED',
          message:
              'You have reached your daily limit for demo mode ($maxLimit requests). Please log in to continue.',
          currentCount: guestCount - 1,
          limit: maxLimit,
        );
      }
      _guestUsage[operation] = guestCount;
      return AIUsageCheckResult(
        allowed: true,
        currentCount: guestCount,
        limit: maxLimit,
      );
    }

    final userId = user.id;

    // 3. Race-condition-proof atomic execution via Supabase RPC
    try {
      final response = await _client.rpc(
        'check_and_consume_ai_limit',
        params: {
          'p_user_id': userId,
          'p_operation': operation,
          'p_max_limit': maxLimit,
        },
      );

      if (response != null && response is Map) {
        final allowed = response['allowed'] == true;
        final count = (response['request_count'] as num? ?? 0).toInt();

        if (!allowed) {
          return AIUsageCheckResult(
            allowed: false,
            errorCode: 'AI_DAILY_LIMIT_REACHED',
            message:
                'You have reached your daily resume processing limit. Please try again tomorrow.',
            currentCount: count,
            limit: maxLimit,
          );
        }

        return AIUsageCheckResult(
          allowed: true,
          currentCount: count,
          limit: maxLimit,
        );
      }
    } catch (e) {
      debugPrint(
          '[AIUsageService] RPC execution note ($e). Using database query fallback...');
    }

    // 4. Transaction query fallback for direct table interaction
    try {
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);

      final existing = await _client
          .from('ai_usage')
          .select('id, request_count')
          .eq('user_id', userId)
          .eq('operation', operation)
          .eq('usage_date', todayStr)
          .maybeSingle();

      if (existing == null) {
        await _client.from('ai_usage').insert({
          'user_id': userId,
          'operation': operation,
          'usage_date': todayStr,
          'request_count': 1,
        });

        return AIUsageCheckResult(
          allowed: true,
          currentCount: 1,
          limit: maxLimit,
        );
      } else {
        final currentCount = (existing['request_count'] as num).toInt();

        if (currentCount >= maxLimit) {
          return AIUsageCheckResult(
            allowed: false,
            errorCode: 'AI_DAILY_LIMIT_REACHED',
            message:
                'You have reached your daily resume processing limit. Please try again tomorrow.',
            currentCount: currentCount,
            limit: maxLimit,
          );
        }

        await _client.from('ai_usage').update({
          'request_count': currentCount + 1,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', existing['id']);

        return AIUsageCheckResult(
          allowed: true,
          currentCount: currentCount + 1,
          limit: maxLimit,
        );
      }
    } catch (dbErr) {
      debugPrint('[AIUsageService] Database error ($dbErr). Failing safely...');
      return AIUsageCheckResult(
        allowed: false,
        errorCode: 'USAGE_CHECK_FAILED',
        message: 'Unable to process the request right now. Please try again later.',
      );
    }
  }

  /// Fetches daily resume usage stats for the current user.
  Future<Map<String, dynamic>> getUserResumeUsage() async {
    final user = _client.auth.currentUser;
    const dailyLimit = 4;
    if (user == null) {
      final used = _guestUsage['tailor_resume'] ?? 0;
      return {
        'daily_limit': dailyLimit,
        'resumes_generated_today': used,
        'remaining': (dailyLimit - used).clamp(0, dailyLimit),
      };
    }
    try {
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      final existing = await _client
          .from('ai_usage')
          .select('request_count')
          .eq('user_id', user.id)
          .eq('usage_date', todayStr)
          .maybeSingle();

      final used = existing != null ? (existing['request_count'] as num).toInt() : 0;
      return {
        'daily_limit': dailyLimit,
        'resumes_generated_today': used,
        'remaining': (dailyLimit - used).clamp(0, dailyLimit),
      };
    } catch (e) {
      return {
        'daily_limit': dailyLimit,
        'resumes_generated_today': 0,
        'remaining': dailyLimit,
      };
    }
  }
}

