import 'package:flutter_test/flutter_test.dart';
import 'package:jobwink/models/resume_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Certifications & Credentials Persistence & Data Flow Tests', () {
    test('1. Certification object creation, serialization to JSON and deserialization from JSON', () {
      const initialResume = ResumeData(
        fullName: 'Nishant Arya',
        email: 'na6236786@gmail.com',
        certifications: [],
      );

      expect(initialResume.certifications.length, equals(0));

      final newCert = ExtracurricularEntry(
        activity: 'AWS Certified Cloud Practitioner',
        organization: 'Amazon Web Services',
        role: 'Associate',
        description: '2026 • https://aws.amazon.com/verification/12345',
      );

      final updatedResume = initialResume.copyWith(
        certifications: [newCert],
      );

      expect(updatedResume.certifications.length, equals(1));
      expect(updatedResume.certifications.first.activity, equals('AWS Certified Cloud Practitioner'));
      expect(updatedResume.certifications.first.organization, equals('Amazon Web Services'));
      expect(updatedResume.certifications.first.role, equals('Associate'));
      expect(updatedResume.certifications.first.description, equals('2026 • https://aws.amazon.com/verification/12345'));

      // Test JSON serialization
      final json = updatedResume.toJson();
      expect(json['certifications'], isA<List>());
      final certsList = json['certifications'] as List;
      expect(certsList.length, equals(1));
      expect(certsList.first['activity'], equals('AWS Certified Cloud Practitioner'));
      expect(certsList.first['organization'], equals('Amazon Web Services'));

      // Test JSON deserialization (Reconstruction / Reload)
      final reloadedResume = ResumeData.fromJson(json);
      expect(reloadedResume.certifications.length, equals(1));
      expect(reloadedResume.certifications.first.activity, equals('AWS Certified Cloud Practitioner'));
      expect(reloadedResume.certifications.first.organization, equals('Amazon Web Services'));
      expect(reloadedResume.certifications.first.role, equals('Associate'));
      expect(reloadedResume.certifications.first.description, equals('2026 • https://aws.amazon.com/verification/12345'));
    });

    test('2. Edit certification in-place updates existing item without duplicates', () {
      final cert1 = ExtracurricularEntry(
        activity: 'AWS Certified Cloud Practitioner',
        organization: 'Amazon Web Services',
        description: '2025',
      );

      var resume = const ResumeData().copyWith(certifications: [cert1]);
      expect(resume.certifications.length, equals(1));

      // Edit item at index 0
      final editedCert = ExtracurricularEntry(
        activity: 'AWS Certified Solutions Architect Professional',
        organization: 'Amazon Web Services',
        description: '2026 • Verified',
      );

      final currentList = List<ExtracurricularEntry>.from(resume.certifications);
      currentList[0] = editedCert;
      resume = resume.copyWith(certifications: currentList);

      expect(resume.certifications.length, equals(1));
      expect(resume.certifications.first.activity, equals('AWS Certified Solutions Architect Professional'));
      expect(resume.certifications.first.description, equals('2026 • Verified'));

      // Check serialization after edit
      final json = resume.toJson();
      final reloaded = ResumeData.fromJson(json);
      expect(reloaded.certifications.length, equals(1));
      expect(reloaded.certifications.first.activity, equals('AWS Certified Solutions Architect Professional'));
    });

    test('3. Multiple certifications persist correctly and remain accessible', () {
      final cert1 = ExtracurricularEntry(
        activity: 'Google Cloud Professional Cloud Architect',
        organization: 'Google Cloud',
        description: '2026',
      );
      final cert2 = ExtracurricularEntry(
        activity: 'Certified Kubernetes Administrator (CKA)',
        organization: 'CNCF',
        description: '2025',
      );
      final extra1 = ExtracurricularEntry(
        activity: 'Open Source Contributor',
        organization: 'Flutter Community',
        description: 'Maintained core plugins',
      );

      final resume = const ResumeData().copyWith(
        certifications: [cert1, cert2],
        extracurriculars: [extra1],
      );

      expect(resume.certifications.length, equals(2));
      expect(resume.extracurriculars.length, equals(1));

      final json = resume.toJson();
      final reloaded = ResumeData.fromJson(json);

      expect(reloaded.certifications.length, equals(2));
      expect(reloaded.certifications[0].activity, equals('Google Cloud Professional Cloud Architect'));
      expect(reloaded.certifications[1].activity, equals('Certified Kubernetes Administrator (CKA)'));
      expect(reloaded.extracurriculars.any((e) => e.activity == 'Open Source Contributor'), isTrue);
    });
  });
}
