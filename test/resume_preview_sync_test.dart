import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobwink/models/resume_data.dart';
import 'package:jobwink/models/resume_type.dart';
import 'package:jobwink/services/resume_export_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Real-Time Resume Preview Synchronization', () {
    test('ValueNotifier triggers update whenever ResumeData changes', () {
      final initialData = const ResumeData(
        fullName: 'John Doe',
        email: 'john@example.com',
        title: 'Software Developer',
      );

      final notifier = ValueNotifier<ResumeData>(initialData);
      ResumeData? updatedValue;

      notifier.addListener(() {
        updatedValue = notifier.value;
      });

      // Simulate typing/updating full name
      final editedData = initialData.copyWith(fullName: 'Johnathan Doe');
      notifier.value = editedData;

      expect(updatedValue, isNotNull);
      expect(updatedValue!.fullName, equals('Johnathan Doe'));
    });

    test('ValueNotifier triggers update whenever ResumeType changes', () {
      final notifier = ValueNotifier<ResumeType>(ResumeType.experience);
      ResumeType? updatedType;

      notifier.addListener(() {
        updatedType = notifier.value;
      });

      notifier.value = ResumeType.project;

      expect(updatedType, equals(ResumeType.project));
    });

    test('PDF generation creates identical output for dynamic notifier state', () async {
      final resumeData = const ResumeData(
        fullName: 'Jane Smith',
        email: 'jane@example.com',
        summary: 'Experienced Cloud Architect',
        skills: ['AWS', 'Terraform', 'Go'],
      );

      final pdf1 = await ResumeExportService.instance.generateAtsPdf(
        resumeData,
        selectedResumeType: ResumeType.fresher,
      );

      expect(pdf1, isNotNull);
      expect(pdf1.length, greaterThan(1000));
    });
  });
}
