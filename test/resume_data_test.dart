import 'package:flutter_test/flutter_test.dart';
import 'package:jobwink/models/resume_data.dart';

void main() {
  group('ResumeData JSON Aggregation & Extracurricular Parsing Tests', () {
    test('Aggregates certifications and extracurriculars from multiple JSON keys', () {
      final jsonMap = {
        'fullName': 'John Doe',
        'certifications': [
          {'name': 'AWS Certified Developer', 'issuer': 'Amazon', 'date': '2023'},
          'Google Cloud Professional Architect'
        ],
        'extracurriculars': [
          {'activity': 'Hackathon Lead', 'organization': 'Tech Club', 'role': 'Organizer'}
        ],
        'certificates': [
          {'title': 'Scrum Master', 'authority': 'Scrum.org'}
        ],
        'awards': [
          'Best Innovation Award 2022'
        ]
      };

      final resume = ResumeData.fromJson(jsonMap);

      expect(resume.certifications.length, equals(3));
      expect(resume.extracurriculars.length, equals(2));

      final certNames = resume.certifications.map((e) => e.activity).toList();
      expect(certNames, containsAll([
        'AWS Certified Developer',
        'Google Cloud Professional Architect',
        'Scrum Master',
      ]));

      final extraNames = resume.extracurriculars.map((e) => e.activity).toList();
      expect(extraNames, containsAll([
        'Hackathon Lead',
        'Best Innovation Award 2022',
      ]));

      // Verify specific details parsed
      final aws = resume.certifications.firstWhere((e) => e.activity == 'AWS Certified Developer');
      expect(aws.organization, equals('Amazon'));

      final hackathon = resume.extracurriculars.firstWhere((e) => e.activity == 'Hackathon Lead');
      expect(hackathon.organization, equals('Tech Club'));
      expect(hackathon.role, equals('Organizer'));

      final scrum = resume.certifications.firstWhere((e) => e.activity == 'Scrum Master');
      expect(scrum.organization, equals('Scrum.org'));
    });

    test('ExtracurricularEntry.fromJson handles both String and Map dynamic inputs', () {
      final stringEntry = ExtracurricularEntry.fromJson('First Aid Certification');
      expect(stringEntry.activity, equals('First Aid Certification'));

      final mapEntry = ExtracurricularEntry.fromJson({
        'title': 'Volunteering',
        'provider': 'Red Cross',
        'role': 'Volunteer Leader',
        'summary': 'Helped organize blood donation camps'
      });

      expect(mapEntry.activity, equals('Volunteering'));
      expect(mapEntry.organization, equals('Red Cross'));
      expect(mapEntry.role, equals('Volunteer Leader'));
      expect(mapEntry.description, equals('Helped organize blood donation camps'));
    });
  });
}
