import 'package:flutter_test/flutter_test.dart';
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
    test('only na6236786@gmail.com is identified as admin', () {
      final service = ResumeLimitService.instance;

      expect(service.isUserAdmin('na6236786@gmail.com'), isTrue);
      expect(service.isUserAdmin('NA6236786@GMAIL.COM'), isTrue);
      expect(service.isUserAdmin(' na6236786@gmail.com '), isTrue);

      expect(service.isUserAdmin('other@gmail.com'), isFalse);
      expect(service.isUserAdmin('admin@jobwink.app'), isFalse);
      expect(service.isUserAdmin(null), isFalse);
      expect(service.isUserAdmin(''), isFalse);
    });
  });

  group('Admin Unlimited Resume Creations Tests', () {
    test('na6236786@gmail.com is recognized as unlimited admin', () {
      final service = ResumeLimitService.instance;
      expect(service.isUserAdmin('na6236786@gmail.com'), isTrue);
      expect(service.isUserAdmin('NA6236786@GMAIL.COM'), isTrue);
      expect(service.isUserAdmin('other_user@example.com'), isFalse);
    });
  });

  group('Resume Creation Limit Enforcement Simulation Tests', () {
    test('guest demo user gets exactly 4 creation attempts per day', () async {
      final service = ResumeLimitService.instance;

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

      // Refund gives back 1 slot
      await service.refundLimit();
      final checkAfterRefund = await service.checkAndReserveLimit();
      expect(checkAfterRefund.allowed, isTrue);
    });
  });
}
