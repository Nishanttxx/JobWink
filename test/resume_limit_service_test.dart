import 'package:flutter_test/flutter_test.dart';
import 'package:jobwink/config/backend_config.dart';
import 'package:jobwink/services/resume_limit_service.dart';

void main() {
  group('ResumeLimitCheckResult Model Tests', () {
    test('default constructor sets default values', () {
      const result = ResumeLimitCheckResult(allowed: true);
      expect(result.allowed, isTrue);
      expect(result.dailyLimit, 4);
      expect(result.usageCount, 0);
      expect(result.remaining, 4);
      expect(result.message, '');
    });

    test('toJson serializes correctly', () {
      const result = ResumeLimitCheckResult(
        allowed: false,
        dailyLimit: 4,
        usageCount: 4,
        remaining: 0,
        message: 'Daily resume limit reached. Please try again tomorrow.',
      );

      final json = result.toJson();
      expect(json['allowed'], isFalse);
      expect(json['daily_limit'], 4);
      expect(json['usage_count'], 4);
      expect(json['remaining'], 0);
      expect(json['message'], contains('Daily resume limit reached'));
    });
  });

  group('AdminUserQuotaInfo Model Tests', () {
    test('fromMap parses database row correctly', () {
      final now = DateTime.now();
      final map = {
        'user_id': '550e8400-e29b-41d4-a716-446655440000',
        'email': 'nishant@example.com',
        'full_name': 'Nishant Arya',
        'daily_limit': 10,
        'usage_count': 3,
        'remaining': 7,
        'usage_date': '2026-08-24',
        'created_at': now.toIso8601String(),
      };

      final info = AdminUserQuotaInfo.fromMap(map);
      expect(info.userId, '550e8400-e29b-41d4-a716-446655440000');
      expect(info.email, 'nishant@example.com');
      expect(info.fullName, 'Nishant Arya');
      expect(info.dailyLimit, 10);
      expect(info.usageCount, 3);
      expect(info.remaining, 7);
      expect(info.usageDate, '2026-08-24');
      expect(info.createdAt?.year, now.year);
    });

    test('fromMap falls back cleanly when optional fields are missing', () {
      final map = {
        'user_id': '123',
        'email': 'test@example.com',
      };

      final info = AdminUserQuotaInfo.fromMap(map);
      expect(info.userId, '123');
      expect(info.email, 'test@example.com');
      expect(info.fullName, isNull);
      expect(info.dailyLimit, 4);
      expect(info.usageCount, 0);
      expect(info.remaining, 0);
    });
  });

  group('Admin Authorization Tests', () {
    test('isUserAdmin returns false when ADMIN_EMAIL not configured', () {
      // When ADMIN_EMAIL dart-define is empty, no user should be admin
      final service = ResumeLimitService.instance;
      if (BackendConfig.adminEmail.isEmpty) {
        expect(service.isUserAdmin('any@email.com'), isFalse);
        expect(service.isUserAdmin(null), isFalse);
      } else {
        // When ADMIN_EMAIL is set, only that exact email is admin
        final adminEmail = BackendConfig.adminEmail;
        expect(service.isUserAdmin(adminEmail), isTrue);
        expect(service.isUserAdmin(adminEmail.toUpperCase()), isTrue);
        expect(service.isUserAdmin(' $adminEmail '), isTrue);
        expect(service.isUserAdmin('other@gmail.com'), isFalse);
        expect(service.isUserAdmin(null), isFalse);
        expect(service.isUserAdmin(''), isFalse);
      }
    });
  });

  group('Admin Unlimited Resume Creations Tests', () {
    test('isUserAdmin respects ADMIN_EMAIL configuration', () {
      final service = ResumeLimitService.instance;
      expect(service.isUserAdmin('other_user@example.com'), isFalse);
      expect(service.isUserAdmin(null), isFalse);
    });
  });

  group('Resume Creation Limit Enforcement Simulation Tests', () {
    test('formatDateOnly formats consistently as YYYY-MM-DD', () {
      final d1 = DateTime(2026, 8, 26);
      expect(ResumeLimitService.formatDateOnly(d1), '2026-08-26');

      final d2 = DateTime(2026, 1, 5);
      expect(ResumeLimitService.formatDateOnly(d2), '2026-01-05');

      final d3 = DateTime(2026, 12, 31);
      expect(ResumeLimitService.formatDateOnly(d3), '2026-12-31');
    });

    test('guest demo user gets exactly 4 creation attempts per day and respects daily reset', () async {
      final service = ResumeLimitService.instance;

      // User usage check before creations
      final initialUsage = await service.getUserResumeUsage();
      expect(initialUsage['daily_limit'], 4);
      expect(initialUsage['usage_date'], ResumeLimitService.formatDateOnly(DateTime.now()));

      // First 4 calls allowed
      final check1 = await service.checkAndReserveLimit();
      expect(check1.allowed, isTrue);

      final check2 = await service.checkAndReserveLimit();
      expect(check2.allowed, isTrue);

      final check3 = await service.checkAndReserveLimit();
      expect(check3.allowed, isTrue);

      final check4 = await service.checkAndReserveLimit();
      expect(check4.allowed, isTrue);

      // 5th attempt rejected
      final check5 = await service.checkAndReserveLimit();
      expect(check5.allowed, isFalse);
      expect(check5.message, contains('Daily resume limit reached'));

      // Check usage returns 4 used and allowed = false
      final fullUsage = await service.getUserResumeUsage();
      expect(fullUsage['usage_count'], 4);
      expect(fullUsage['remaining'], 0);
      expect(fullUsage['allowed'], isFalse);

      // Refund gives back 1 slot on failure
      await service.refundLimit();
      final checkAfterRefund = await service.checkAndReserveLimit();
      expect(checkAfterRefund.allowed, isTrue);
    });
  });

  group('ResumeLimitService.normalizeUsageMap Tests', () {
    test('1. Normalizes raw Supabase RPC output with "used" and "limit" keys for new user', () {
      final rpcOutput = {
        'used': 0,
        'limit': 4,
        'remaining': 4,
        'usage_date': ResumeLimitService.formatDateOnly(DateTime.now()),
      };

      final normalized = ResumeLimitService.normalizeUsageMap(rpcOutput);

      expect(normalized['allowed'], isTrue);
      expect(normalized['daily_limit'], 4);
      expect(normalized['limit'], 4);
      expect(normalized['usage_count'], 0);
      expect(normalized['used'], 0);
      expect(normalized['resumes_generated_today'], 0);
      expect(normalized['remaining'], 4);
      expect(normalized['is_unlimited'], isFalse);
    });

    test('2. Normalizes database row with legacy "resumes_generated_today" and "daily_limit"', () {
      final dbRow = {
        'daily_limit': 10,
        'resumes_generated_today': 3,
        'usage_date': ResumeLimitService.formatDateOnly(DateTime.now()),
      };

      final normalized = ResumeLimitService.normalizeUsageMap(dbRow);

      expect(normalized['allowed'], isTrue);
      expect(normalized['daily_limit'], 10);
      expect(normalized['usage_count'], 3);
      expect(normalized['remaining'], 7);
    });

    test('3. Correctly flags allowed = false when usage reaches or exceeds limit', () {
      final atLimit = {
        'used': 4,
        'limit': 4,
        'usage_date': ResumeLimitService.formatDateOnly(DateTime.now()),
      };

      final normalized = ResumeLimitService.normalizeUsageMap(atLimit);

      expect(normalized['allowed'], isFalse);
      expect(normalized['usage_count'], 4);
      expect(normalized['remaining'], 0);

      final overLimit = {
        'used': 5,
        'limit': 4,
        'usage_date': ResumeLimitService.formatDateOnly(DateTime.now()),
      };

      final normOver = ResumeLimitService.normalizeUsageMap(overLimit);
      expect(normOver['allowed'], isFalse);
      expect(normOver['remaining'], 0);
    });

    test('4. Resets usage to 0 if record is from a previous calendar day', () {
      final yesterday = {
        'used': 4,
        'limit': 4,
        'usage_date': '2020-01-01',
      };

      final normalized = ResumeLimitService.normalizeUsageMap(yesterday);

      expect(normalized['allowed'], isTrue);
      expect(normalized['usage_count'], 0);
      expect(normalized['used'], 0);
      expect(normalized['remaining'], 4);
    });

    test('5. Grants unlimited access for admin users regardless of usage count', () {
      final adminRow = {
        'used': 50,
        'limit': 4,
        'usage_date': ResumeLimitService.formatDateOnly(DateTime.now()),
      };

      final normalized = ResumeLimitService.normalizeUsageMap(adminRow, isAdmin: true);

      expect(normalized['allowed'], isTrue);
      expect(normalized['daily_limit'], 999999);
      expect(normalized['remaining'], 999999);
      expect(normalized['is_unlimited'], isTrue);
    });

    test('6. Empty or missing map defaults to allowed = true with 4 remaining', () {
      final empty = <String, dynamic>{};
      final normalized = ResumeLimitService.normalizeUsageMap(empty);

      expect(normalized['allowed'], isTrue);
      expect(normalized['daily_limit'], 4);
      expect(normalized['usage_count'], 0);
      expect(normalized['remaining'], 4);
    });
  });
}
