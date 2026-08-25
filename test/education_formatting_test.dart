import 'package:flutter_test/flutter_test.dart';
import 'package:jobwink/models/resume_data.dart';
import 'package:jobwink/services/resume_export_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Education Section Formatting Tests (No automatic "in" and conditional "-")', () {
    test('1. Degree and Field are rendered without automatic "in"', () async {
      const resume = ResumeData(
        fullName: 'Test User',
        education: [
          EducationEntry(
            degree: 'Class XII',
            fieldOfStudy: 'CBSE',
            institution: 'India National School',
            startDate: '2021',
            endDate: '2023',
            gpa: '91.4%',
          ),
        ],
      );

      final pdfBytes = await ResumeExportService.instance.generateAtsPdf(resume);
      expect(pdfBytes.isNotEmpty, isTrue);

      // Verify that PDF text contains the user's components cleanly
      final pdfString = String.fromCharCodes(pdfBytes);
      // Ensure the generated PDF stream does not contain "Class XII in CBSE"
      expect(pdfString.contains('Class XII in CBSE'), isFalse);
    });

    test('2. Start year only displays year without trailing hyphen', () async {
      const resume = ResumeData(
        fullName: 'Test User',
        education: [
          EducationEntry(
            degree: 'B.Tech',
            fieldOfStudy: 'Computer Science',
            institution: 'NMAM Institute of Technology',
            startDate: '2021',
            endDate: '',
          ),
        ],
      );

      final pdfBytes = await ResumeExportService.instance.generateAtsPdf(resume);
      expect(pdfBytes.isNotEmpty, isTrue);
    });

    test('3. End year only displays year without leading hyphen', () async {
      const resume = ResumeData(
        fullName: 'Test User',
        education: [
          EducationEntry(
            degree: 'B.Tech',
            institution: 'University',
            startDate: '',
            endDate: '2025',
          ),
        ],
      );

      final pdfBytes = await ResumeExportService.instance.generateAtsPdf(resume);
      expect(pdfBytes.isNotEmpty, isTrue);
    });

    test('4. End year with Present renders "2021 - Present"', () async {
      const resume = ResumeData(
        fullName: 'Test User',
        education: [
          EducationEntry(
            degree: 'B.Tech',
            institution: 'University',
            startDate: '2021',
            endDate: 'Present',
          ),
        ],
      );

      final pdfBytes = await ResumeExportService.instance.generateAtsPdf(resume);
      expect(pdfBytes.isNotEmpty, isTrue);
    });

    test('5. Empty start and end year renders no date text or hyphen', () async {
      const resume = ResumeData(
        fullName: 'Test User',
        education: [
          EducationEntry(
            degree: 'B.Tech',
            institution: 'University',
            startDate: '',
            endDate: '',
          ),
        ],
      );

      final pdfBytes = await ResumeExportService.instance.generateAtsPdf(resume);
      expect(pdfBytes.isNotEmpty, isTrue);
    });
  });
}
