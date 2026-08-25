import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Result object for resume creation quota check.
class ResumeLimitCheckResult {
  final bool allowed;
  final int dailyLimit;
  final int usageCount;
  final int remaining;
  final String message;

  const ResumeLimitCheckResult({
    required this.allowed,
    this.dailyLimit = 4,
    this.usageCount = 0,
    this.remaining = 4,
    this.message = '',
  });

  Map<String, dynamic> toJson() => {
        'allowed': allowed,
        'daily_limit': dailyLimit,
        'usage_count': usageCount,
        'remaining': remaining,
        'message': message,
      };

  @override
  String toString() =>
      'ResumeLimitCheckResult(allowed: $allowed, dailyLimit: $dailyLimit, usageCount: $usageCount, remaining: $remaining)';
}

/// Model representing a user row on the Admin Dashboard.
class AdminUserQuotaInfo {
  final String userId;
  final String email;
  final String? fullName;
  final int dailyLimit;
  final int usageCount;
  final int remaining;
  final String usageDate;
  final DateTime? createdAt;

  const AdminUserQuotaInfo({
    required this.userId,
    required this.email,
    this.fullName,
    required this.dailyLimit,
    required this.usageCount,
    required this.remaining,
    required this.usageDate,
    this.createdAt,
  });

  factory AdminUserQuotaInfo.fromMap(Map<String, dynamic> map) {
    return AdminUserQuotaInfo(
      userId: map['user_id']?.toString() ?? '',
      email: map['email']?.toString() ?? 'User',
      fullName: map['full_name'] as String?,
      dailyLimit: (map['daily_limit'] as num? ?? 4).toInt(),
      usageCount: (map['usage_count'] as num? ?? map['resumes_generated_today'] as num? ?? 0).toInt(),
      remaining: (map['remaining'] as num? ?? 0).toInt(),
      usageDate: map['usage_date']?.toString() ?? '',
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) : null,
    );
  }
}

/// Dedicated, isolated service enforcing daily resume creation limits and admin management.
class ResumeLimitService {
  static final ResumeLimitService instance = ResumeLimitService._internal();
  ResumeLimitService._internal();

  SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  // In-memory demo mode tracker
  int _guestUsageCount = 0;
  DateTime _guestUsageDate = DateTime.now();

  /// Checks if the authenticated user is the designated admin account.
  static const String targetAdminEmail = 'na6236786@gmail.com';

  bool isUserAdmin(String? email) {
    if (email == null) return false;
    return email.trim().toLowerCase() == targetAdminEmail;
  }

  /// Atomically checks and reserves one unit of resume creation quota.
  ///
  /// Calls the Supabase PostgreSQL RPC `check_and_reserve_resume_limit`.
  /// Admin (na6236786@gmail.com) has unlimited resume creations.
  /// If the limit is reached for normal users, returns `allowed: false` with message.
  Future<ResumeLimitCheckResult> checkAndReserveLimit() async {
    final client = _client;
    final user = client?.auth.currentUser;

    // 0. Admin Exemption: na6236786@gmail.com has no limit
    if (user != null && isUserAdmin(user.email)) {
      return const ResumeLimitCheckResult(
        allowed: true,
        dailyLimit: 999999,
        usageCount: 0,
        remaining: 999999,
      );
    }

    // Guest / Demo mode quota handling
    if (user == null || client == null) {
      final now = DateTime.now();
      if (now.day != _guestUsageDate.day || now.month != _guestUsageDate.month || now.year != _guestUsageDate.year) {
        _guestUsageCount = 0;
        _guestUsageDate = now;
      }

      const defaultLimit = 4;
      if (_guestUsageCount >= defaultLimit) {
        return const ResumeLimitCheckResult(
          allowed: false,
          dailyLimit: defaultLimit,
          usageCount: defaultLimit,
          remaining: 0,
          message: 'Daily resume limit reached. Please try again tomorrow.',
        );
      }

      _guestUsageCount++;
      return ResumeLimitCheckResult(
        allowed: true,
        dailyLimit: defaultLimit,
        usageCount: _guestUsageCount,
        remaining: defaultLimit - _guestUsageCount,
      );
    }

    // 1. Primary: Atomic server-side execution via RPC
    try {
      final response = await client.rpc('check_and_reserve_resume_limit');

      if (response != null && response is Map) {
        final allowed = response['allowed'] == true;
        final dailyLimit = (response['daily_limit'] as num? ?? 4).toInt();
        final usageCount = (response['usage_count'] as num? ?? 0).toInt();
        final remaining = (response['remaining'] as num? ?? 0).toInt();

        if (!allowed) {
          return ResumeLimitCheckResult(
            allowed: false,
            dailyLimit: dailyLimit,
            usageCount: usageCount,
            remaining: 0,
            message: 'Daily resume limit reached. Please try again tomorrow.',
          );
        }

        return ResumeLimitCheckResult(
          allowed: true,
          dailyLimit: dailyLimit,
          usageCount: usageCount,
          remaining: remaining,
        );
      }
    } catch (rpcErr) {
      debugPrint('[ResumeLimitService] RPC note: $rpcErr. Evaluating via database fallback...');
    }

    // 2. Direct Table Transaction Fallback (if RPC is pending or network fallback)
    try {
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      final userId = user.id;

      final existing = await client
          .from('user_resume_limits')
          .select('id, daily_limit, usage_count, usage_date')
          .eq('user_id', userId)
          .maybeSingle();

      if (existing == null) {
        await client.from('user_resume_limits').insert({
          'user_id': userId,
          'daily_limit': 4,
          'usage_count': 1,
          'usage_date': todayStr,
        });

        return const ResumeLimitCheckResult(
          allowed: true,
          dailyLimit: 4,
          usageCount: 1,
          remaining: 3,
        );
      } else {
        final recordDate = existing['usage_date']?.toString() ?? '';
        final dailyLimit = (existing['daily_limit'] as num? ?? 4).toInt();
        int currentUsage = (existing['usage_count'] as num? ?? 0).toInt();

        // Lazy daily reset
        if (recordDate != todayStr) {
          currentUsage = 0;
        }

        if (currentUsage >= dailyLimit) {
          return ResumeLimitCheckResult(
            allowed: false,
            dailyLimit: dailyLimit,
            usageCount: currentUsage,
            remaining: 0,
            message: 'Daily resume limit reached. Please try again tomorrow.',
          );
        }

        final newUsage = currentUsage + 1;
        await client.from('user_resume_limits').update({
          'usage_count': newUsage,
          'usage_date': todayStr,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', existing['id']);

        return ResumeLimitCheckResult(
          allowed: true,
          dailyLimit: dailyLimit,
          usageCount: newUsage,
          remaining: (dailyLimit - newUsage).clamp(0, dailyLimit),
        );
      }
    } catch (dbErr) {
      debugPrint('[ResumeLimitService] Database error: $dbErr');
      // Safety fail-open or graceful error
      return const ResumeLimitCheckResult(
        allowed: false,
        dailyLimit: 4,
        usageCount: 4,
        remaining: 0,
        message: 'Unable to verify resume limit. Please try again in a moment.',
      );
    }
  }

  /// Refunds a reserved creation if the resume parsing / creation pipeline fails.
  Future<void> refundLimit() async {
    final client = _client;
    final user = client?.auth.currentUser;
    if (user == null || client == null) {
      if (_guestUsageCount > 0) _guestUsageCount--;
      return;
    }

    try {
      await client.rpc('refund_resume_limit');
    } catch (e) {
      debugPrint('[ResumeLimitService] Refund note: $e');
    }
  }

  /// Retrieves the current user's daily quota and usage status.
  Future<Map<String, dynamic>> getUserResumeUsage() async {
    final client = _client;
    final user = client?.auth.currentUser;
    const defaultLimit = 4;

    // Admin has unlimited creations
    if (user != null && isUserAdmin(user.email)) {
      return {
        'daily_limit': 999999,
        'usage_count': 0,
        'resumes_generated_today': 0,
        'remaining': 999999,
        'allowed': true,
        'is_unlimited': true,
      };
    }

    if (user == null || client == null) {
      final now = DateTime.now();
      if (now.day != _guestUsageDate.day || now.month != _guestUsageDate.month || now.year != _guestUsageDate.year) {
        _guestUsageCount = 0;
        _guestUsageDate = now;
      }
      return {
        'daily_limit': defaultLimit,
        'usage_count': _guestUsageCount,
        'resumes_generated_today': _guestUsageCount,
        'remaining': (defaultLimit - _guestUsageCount).clamp(0, defaultLimit),
        'allowed': _guestUsageCount < defaultLimit,
      };
    }

    try {
      final res = await client.rpc('get_user_resume_usage');
      if (res != null && res is Map) {
        return Map<String, dynamic>.from(res);
      }
    } catch (_) {}

    try {
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      final existing = await client
          .from('user_resume_limits')
          .select('daily_limit, usage_count, usage_date')
          .eq('user_id', user.id)
          .maybeSingle();

      if (existing != null) {
        final dailyLimit = (existing['daily_limit'] as num? ?? defaultLimit).toInt();
        final recordDate = existing['usage_date']?.toString() ?? '';
        final used = recordDate == todayStr ? (existing['usage_count'] as num? ?? 0).toInt() : 0;

        return {
          'daily_limit': dailyLimit,
          'usage_count': used,
          'resumes_generated_today': used,
          'remaining': (dailyLimit - used).clamp(0, dailyLimit),
          'allowed': used < dailyLimit,
        };
      }
    } catch (_) {}

    return {
      'daily_limit': defaultLimit,
      'usage_count': 0,
      'resumes_generated_today': 0,
      'remaining': defaultLimit,
      'allowed': true,
    };
  }

  // ── Admin Dashboard API ───────────────────────────────────────────────────

  /// Fetches system overview statistics for the admin dashboard.
  Future<Map<String, dynamic>> getAdminStats() async {
    final client = _client;
    if (client == null) {
      return {
        'totalUsers': 0,
        'activeUsersToday': 0,
        'resumesGeneratedToday': 0,
        'usersAtLimit': 0,
      };
    }

    try {
      final res = await client.rpc('get_admin_dashboard_stats');
      if (res != null && res is Map) {
        return Map<String, dynamic>.from(res);
      }
    } catch (e) {
      debugPrint('[ResumeLimitService] getAdminStats RPC note: $e. Using direct queries fallback...');
    }

    // Direct database query fallback
    try {
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      int totalUsers = 0;
      try {
        final profilesRes = await client.from('profiles').select('id');
        totalUsers = (profilesRes as List).length;
      } catch (_) {}

      final limits = await client.from('user_resume_limits').select('*');
      int activeToday = 0;
      int resumesToday = 0;
      int atLimit = 0;

      for (final row in (limits as List)) {
        final date = row['usage_date']?.toString() ?? '';
        final used = (row['usage_count'] as num? ?? row['resumes_generated_today'] as num? ?? 0).toInt();
        final limit = (row['daily_limit'] as num? ?? 4).toInt();

        if (date == todayStr) {
          if (used > 0) activeToday++;
          resumesToday += used;
          if (used >= limit) atLimit++;
        }
      }

      return {
        'totalUsers': totalUsers > 0 ? totalUsers : limits.length,
        'activeUsersToday': activeToday,
        'resumesGeneratedToday': resumesToday,
        'usersAtLimit': atLimit,
      };
    } catch (fallbackErr) {
      debugPrint('[ResumeLimitService] Stats fallback error: $fallbackErr');
    }

    return {
      'totalUsers': 0,
      'activeUsersToday': 0,
      'resumesGeneratedToday': 0,
      'usersAtLimit': 0,
    };
  }

  /// Fetches all users and their quota status for the admin dashboard.
  Future<List<AdminUserQuotaInfo>> getAdminUsers() async {
    final client = _client;
    if (client == null) return [];

    try {
      final res = await client.rpc('get_admin_users');
      if (res != null && res is List) {
        return res
            .map((item) => AdminUserQuotaInfo.fromMap(Map<String, dynamic>.from(item as Map)))
            .toList();
      }
    } catch (e) {
      debugPrint('[ResumeLimitService] getAdminUsers RPC note: $e. Using direct queries fallback...');
    }

    // Direct table query fallback
    try {
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      final profiles = await client.from('profiles').select('id, email, full_name, created_at');
      final limits = await client.from('user_resume_limits').select('user_id, daily_limit, usage_count, resumes_generated_today, usage_date');

      final limitsMap = <String, Map<String, dynamic>>{};
      for (final row in (limits as List)) {
        final uid = row['user_id']?.toString() ?? '';
        if (uid.isNotEmpty) limitsMap[uid] = Map<String, dynamic>.from(row as Map);
      }

      final result = <AdminUserQuotaInfo>[];
      for (final prof in (profiles as List)) {
        final uid = prof['id']?.toString() ?? '';
        final lim = limitsMap[uid];
        final dailyLimit = (lim?['daily_limit'] as num? ?? 4).toInt();
        final date = lim?['usage_date']?.toString() ?? todayStr;
        final rawUsed = (lim?['usage_count'] as num? ?? lim?['resumes_generated_today'] as num? ?? 0).toInt();
        final used = date == todayStr ? rawUsed : 0;
        final remaining = (dailyLimit - used).clamp(0, 999999);

        result.add(AdminUserQuotaInfo(
          userId: uid,
          email: prof['email']?.toString() ?? 'User',
          fullName: prof['full_name'] as String?,
          dailyLimit: dailyLimit,
          usageCount: used,
          remaining: remaining,
          usageDate: date,
          createdAt: prof['created_at'] != null ? DateTime.tryParse(prof['created_at'].toString()) : null,
        ));
      }

      return result;
    } catch (fallbackErr) {
      debugPrint('[ResumeLimitService] Users fallback error: $fallbackErr');
    }

    return [];
  }

  /// Updates a user's daily resume creation limit.
  Future<void> updateDailyLimit(String userId, int newLimit) async {
    final client = _client;
    if (client == null) return;

    try {
      await client.rpc(
        'update_user_resume_limit',
        params: {
          'p_user_id': userId,
          'p_new_limit': newLimit,
        },
      );
    } catch (e) {
      debugPrint('[ResumeLimitService] updateDailyLimit error: $e');
      rethrow;
    }
  }

  /// Resets a user's resume creations for today to 0.
  Future<void> resetUserUsage(String userId) async {
    final client = _client;
    if (client == null) return;

    try {
      await client.rpc(
        'reset_user_resume_usage',
        params: {
          'p_user_id': userId,
        },
      );
    } catch (e) {
      debugPrint('[ResumeLimitService] resetUserUsage error: $e');
      rethrow;
    }
  }
}
