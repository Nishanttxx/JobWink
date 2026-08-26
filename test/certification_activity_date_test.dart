import 'package:flutter_test/flutter_test.dart';
import 'package:jobwink/models/resume_data.dart';
import 'package:jobwink/services/resume_export_service.dart';

void main() {
  group('Certification / Activity Date & Link Formatting Tests', () {
    test('1. Both Start and End dates provided formats as "Start – End"', () {
      const entry = ExtracurricularEntry(
        activity: 'AWS Certified Solutions Architect',
        organization: 'Amazon Web Services',
        startMonth: 'Aug',
        startYear: '2023',
        endMonth: 'Aug',
        endYear: '2025',
      );

      expect(entry.formattedDate, 'Aug 2023 – Aug 2025');
    });

    test('2. Only End date provided formats as "End" without leading "-" or separator', () {
      const entry = ExtracurricularEntry(
        activity: 'Postman API Fundamentals Student Expert',
        organization: 'Postman',
        endMonth: 'Aug',
        endYear: '2025',
      );

      expect(entry.formattedDate, 'Aug 2025');
      expect(entry.formattedDate.startsWith('-'), isFalse);
      expect(entry.formattedDate.startsWith('–'), isFalse);
      expect(entry.formattedDate.startsWith('—'), isFalse);
    });

    test('3. Only Start date provided formats as "Start" without trailing separator or "Present"', () {
      const entry = ExtracurricularEntry(
        activity: 'Open Source Contributor',
        organization: 'GitHub',
        startMonth: 'Aug',
        startYear: '2023',
      );

      expect(entry.formattedDate, 'Aug 2023');
      expect(entry.formattedDate.endsWith('-'), isFalse);
      expect(entry.formattedDate.endsWith('–'), isFalse);
      expect(entry.formattedDate.contains('Present'), isFalse);
    });

    test('4. Neither date provided returns empty string without separators', () {
      const entry = ExtracurricularEntry(
        activity: 'Member of CSI',
        organization: 'Computer Society of India',
      );

      expect(entry.formattedDate, '');
      expect(entry.formattedDate.contains('null'), isFalse);
      expect(entry.formattedDate.contains('-'), isFalse);
      expect(entry.formattedDate.contains('–'), isFalse);
    });

    test('5. Serialization and deserialization preserves discrete month and year fields', () {
      const entry = ExtracurricularEntry(
        activity: 'Google Cloud Certified Professional',
        role: 'Cloud Architect',
        organization: 'Google Cloud',
        description: 'Credential ID 998877',
        startMonth: 'Jan',
        startYear: '2024',
        endMonth: 'Jan',
        endYear: '2026',
      );

      final json = entry.toJson();
      expect(json['startMonth'], 'Jan');
      expect(json['startYear'], '2024');
      expect(json['endMonth'], 'Jan');
      expect(json['endYear'], '2026');
      expect(json['startDate'], 'Jan 2024');
      expect(json['endDate'], 'Jan 2026');

      final fromJson = ExtracurricularEntry.fromJson(json);
      expect(fromJson.startMonth, 'Jan');
      expect(fromJson.startYear, '2024');
      expect(fromJson.endMonth, 'Jan');
      expect(fromJson.endYear, '2026');
      expect(fromJson.formattedDate, 'Jan 2024 – Jan 2026');
    });

    test('6. Legacy date string parsing compatibility', () {
      final jsonLegacy = {
        'activity': 'Certified Kubernetes Administrator',
        'organization': 'Linux Foundation',
        'startDate': 'Aug 2022',
        'endDate': 'Aug 2025',
      };

      final parsed = ExtracurricularEntry.fromJson(jsonLegacy);
      expect(parsed.startMonth, 'Aug');
      expect(parsed.startYear, '2022');
      expect(parsed.endMonth, 'Aug');
      expect(parsed.endYear, '2025');
      expect(parsed.formattedDate, 'Aug 2022 – Aug 2025');
    });

    test('7. PDF generation with single end date certification renders without errors', () async {
      final resume = ResumeData(
        fullName: 'Nishant Arya',
        email: 'nishant@example.com',
        phone: '+918102908376',
        extracurriculars: const [
          ExtracurricularEntry(
            activity: 'AWS Certified Developer Associate',
            organization: 'Amazon Web Services',
            endMonth: 'Aug',
            endYear: '2025',
          ),
          ExtracurricularEntry(
            activity: 'Core Member',
            organization: 'Finite Loop Club',
            startMonth: 'Aug',
            startYear: '2023',
            endMonth: 'Aug',
            endYear: '2025',
          ),
        ],
      );

      final pdfBytes = await ResumeExportService.instance.generateAtsPdf(resume);
      expect(pdfBytes.isNotEmpty, isTrue);
      expect(pdfBytes.length, greaterThan(1500));
    });

    test('8. Certificate with link is serialized and deserialized properly', () {
      const entry = ExtracurricularEntry(
        activity: 'AWS Certified Solutions Architect',
        organization: 'Amazon Web Services',
        url: 'https://www.credly.com/badges/12345',
        endMonth: 'Aug',
        endYear: '2025',
      );

      final json = entry.toJson();
      expect(json['url'], 'https://www.credly.com/badges/12345');
      expect(json['link'], 'https://www.credly.com/badges/12345');

      final fromJson = ExtracurricularEntry.fromJson(json);
      expect(fromJson.url, 'https://www.credly.com/badges/12345');
      expect(fromJson.link, 'https://www.credly.com/badges/12345');
    });

    test('9. Certificate without link does not output placeholder or null', () {
      const entry = ExtracurricularEntry(
        activity: 'Leadership Award',
        organization: 'Student Council',
      );

      expect(entry.url, '');
      expect(entry.link, '');
      expect(entry.url.contains('null'), isFalse);
      expect(entry.url.contains('N/A'), isFalse);
    });

    test('10. PDF generation with clickable certificate link renders accurately', () async {
      final resume = ResumeData(
        fullName: 'Nishant Arya',
        email: 'nishant@example.com',
        phone: '+918102908376',
        extracurriculars: const [
          ExtracurricularEntry(
            activity: 'AWS Cloud Practitioner',
            organization: 'Amazon Web Services',
            url: 'https://example.com/certificate/123',
            endMonth: 'Aug',
            endYear: '2025',
          ),
          ExtracurricularEntry(
            activity: 'President',
            organization: 'Tech Club',
            startMonth: 'Aug',
            startYear: '2023',
          ),
        ],
      );

      final pdfBytes = await ResumeExportService.instance.generateAtsPdf(resume);
      expect(pdfBytes.isNotEmpty, isTrue);
      expect(pdfBytes.length, greaterThan(1500));
    });
  });
}
