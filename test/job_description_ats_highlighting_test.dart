import 'package:flutter_test/flutter_test.dart';
import 'package:jobwink/models/resume_data.dart';
import 'package:jobwink/services/ai_service.dart';
import 'package:jobwink/services/resume_export_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Job Description ATS & Keyword Highlighting Tests', () {
    test('1. Empty JD returns empty result with 0% ATS score and 0 match score', () async {
      final resume = ResumeData(
        fullName: 'Nishant Arya',
        skills: ['Python', 'Docker', 'PostgreSQL'],
      );

      final result = await AIService.instance.analyzeJobKeywords(
        jobDescription: '',
        currentResume: resume,
      );

      expect(result.extractedJobKeywords, isEmpty);
      expect(result.matchedKeywords, isEmpty);
      expect(result.missingKeywords, isEmpty);
      expect(result.atsScore, 0.0);
      expect(result.matchScore, 0.0);
    });

    test('2. JD with matching skills produces accurate ATS score and matched keywords', () async {
      final resume = ResumeData(
        fullName: 'Nishant Arya',
        email: 'nishant@example.com',
        phone: '+91 9876543210',
        summary: 'Experienced Software Engineer skilled in Python, Docker, and REST APIs.',
        skills: ['Python', 'Docker', 'PostgreSQL', 'Git'],
        experience: [
          ExperienceEntry(
            role: 'Backend Developer',
            company: 'TechCorp',
            description: ['Built scalable microservices using Python and Docker.'],
          ),
        ],
        education: [
          EducationEntry(
            degree: 'B.Tech',
            fieldOfStudy: 'Computer Science',
            institution: 'NIT',
          ),
        ],
      );

      const jd = '''
      We are looking for a Senior Software Engineer.
      Requirements:
      - Strong proficiency in Python and Docker
      - Experience with PostgreSQL and REST APIs
      - Knowledge of Kubernetes and AWS
      ''';

      final result = await AIService.instance.analyzeJobKeywords(
        jobDescription: jd,
        currentResume: resume,
        targetJobTitle: 'Senior Software Engineer',
      );

      expect(result.extractedJobKeywords, isNotEmpty);
      expect(result.matchedKeywords, contains('Python'));
      expect(result.matchedKeywords, contains('Docker'));
      expect(result.matchedKeywords, contains('PostgreSQL'));
      expect(result.missingKeywords, contains('Kubernetes'));
      expect(result.missingKeywords, contains('AWS'));

      // Accurate non-zero ATS score
      expect(result.atsScore, greaterThan(30.0));
      expect(result.atsScore, lessThanOrEqualTo(100.0));
      expect(result.matchScore, greaterThan(30.0));
    });

    test('3. CRITICAL RULE: ResumeData content is never modified or invented', () async {
      final resume = ResumeData(
        fullName: 'Nishant Arya',
        skills: ['Python', 'SQL'],
        experience: [
          ExperienceEntry(role: 'Developer', company: 'Startup', description: ['Wrote Python code.']),
        ],
      );

      const jd = '''
      Looking for Kubernetes, Rust, Ruby on Rails, Terraform expert.
      ''';

      final originalSkillsCount = resume.skills.length;
      final originalExpCount = resume.experience.length;

      final result = await AIService.instance.analyzeJobKeywords(
        jobDescription: jd,
        currentResume: resume,
      );

      // Verify ResumeData is untouched
      expect(resume.skills.length, originalSkillsCount);
      expect(resume.experience.length, originalExpCount);
      expect(resume.skills, ['Python', 'SQL']);
      expect(result.missingKeywords, contains('Kubernetes'));
      expect(result.missingKeywords, contains('Rust'));
      expect(result.matchedKeywords, isEmpty);
      expect(result.atsScore, 0.0);
    });

    test('4. PDF generation succeeds with matched highlightKeywords without altering structure', () async {
      final resume = ResumeData(
        fullName: 'Nishant Arya',
        email: 'nishant@example.com',
        phone: '+91 9876543210',
        summary: 'Proficient in Python, Docker, and REST APIs.',
        skills: ['Python', 'Docker', 'PostgreSQL'],
        experience: [
          ExperienceEntry(
            role: 'Backend Developer',
            company: 'TechCorp',
            description: ['Developed REST APIs using Python.'],
          ),
        ],
        education: [
          EducationEntry(
            degree: 'B.Tech',
            fieldOfStudy: 'CSE',
            institution: 'University',
          ),
        ],
      );

      final pdfBytes = await ResumeExportService.instance.generateAtsPdf(
        resume,
        highlightKeywords: ['Python', 'Docker', 'REST APIs'],
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.isNotEmpty, isTrue);
      // Valid PDF magic header %PDF
      expect(String.fromCharCodes(pdfBytes.take(4)), '%PDF');
    });

    test('5. Section 26 Test Case: AI/ML Intern with Python, Docker, REST APIs vs AWS & TensorFlow', () async {
      final resume = ResumeData(
        fullName: 'Alex Chen',
        email: 'alex.chen@example.com',
        title: 'Software Developer',
        summary: 'Aspiring AI engineer proficient in Python and REST APIs.',
        skills: ['Python', 'Docker', 'REST APIs'],
        projects: [
          ProjectEntry(
            name: 'AI Resume Scanner',
            technologies: ['Python', 'Gemini', 'Machine Learning'],
            description: 'AI-powered application using Python and Gemini for document analysis.',
          ),
        ],
        experience: [
          ExperienceEntry(
            role: 'Junior Developer',
            company: 'CodeLabs',
            description: ['Developed REST APIs using Python.'],
          ),
        ],
        education: [
          EducationEntry(
            degree: 'B.Tech',
            fieldOfStudy: 'Computer Science',
            institution: 'Tech Institute',
          ),
        ],
      );

      const jd = '''
      AI/ML Intern with strong Python, machine learning, REST API and Docker experience. Knowledge of AWS and TensorFlow is preferred.
      ''';

      final result = await AIService.instance.analyzeJobKeywords(
        jobDescription: jd,
        currentResume: resume,
        targetJobTitle: 'AI/ML Intern',
      );

      expect(result.matchedKeywords, contains('Python'));
      expect(result.matchedKeywords, contains('Docker'));
      expect(result.matchedKeywords, contains('REST APIs'));
      expect(result.missingKeywords, contains('AWS'));
      expect(result.missingKeywords, contains('TensorFlow'));

      expect(result.atsScore, greaterThan(40.0));
      expect(result.categoryScores['keywordSkillMatch'], greaterThan(10));
      expect(result.categoryScores['projectMatch'], greaterThan(5));
      expect(result.strengths, isNotEmpty);
      expect(result.gaps, isNotEmpty);
    });

    test('6. Section 27 Test Case: Senior Java Backend Engineer vs Student with Python/Flutter (No False Java Match)', () async {
      final studentResume = ResumeData(
        fullName: 'Sam Student',
        email: 'sam@univ.edu',
        title: 'B.Tech Student',
        summary: 'Computer science student building mobile apps.',
        skills: ['Python', 'Flutter', 'Firebase', 'JavaScript'],
        projects: [
          ProjectEntry(
            name: 'Campus Mobile App',
            technologies: ['Flutter', 'Firebase'],
            description: 'Mobile social app for university students.',
          ),
        ],
        education: [
          EducationEntry(
            degree: 'B.Tech',
            fieldOfStudy: 'Computer Science',
            institution: 'State University',
          ),
        ],
      );

      const jd = '''
      Senior Java Backend Engineer with 8+ years of experience in Java, Spring Boot, Kubernetes and AWS.
      ''';

      final result = await AIService.instance.analyzeJobKeywords(
        jobDescription: jd,
        currentResume: studentResume,
        targetJobTitle: 'Senior Java Backend Engineer',
      );

      // Java must NOT match JavaScript
      expect(result.matchedKeywords.contains('Java'), isFalse);
      expect(result.missingKeywords, contains('Kubernetes'));
      expect(result.missingKeywords, contains('AWS'));

      // Low ATS score reflecting mismatch
      expect(result.atsScore, lessThan(45.0));
    });

    test('7. Structured JSON schema and category score validation consistency', () {
      final jsonResponse = {
        'atsScore': 78,
        'summary': 'Strong match for role.',
        'categoryScores': {
          'keywordSkillMatch': 24,
          'experienceMatch': 16,
          'projectMatch': 12,
          'responsibilityMatch': 11,
          'educationMatch': 8,
          'overallRelevance': 7,
        },
        'matchedKeywords': ['Python', 'Docker', 'REST APIs'],
        'partiallyMatchedKeywords': ['Machine Learning'],
        'missingKeywords': ['AWS', 'TensorFlow'],
        'strengths': ['Strong Python experience'],
        'gaps': ['AWS is missing'],
      };

      final parsed = JobKeywordsAnalysisResult.fromJson(jsonResponse);
      expect(parsed.atsScore, 78.0);
      expect(parsed.categoryScores['keywordSkillMatch'], 24);
      expect(parsed.categoryScores['experienceMatch'], 16);
      expect(parsed.categoryScores['projectMatch'], 12);
      expect(parsed.categoryScores['responsibilityMatch'], 11);
      expect(parsed.categoryScores['educationMatch'], 8);
      expect(parsed.categoryScores['overallRelevance'], 7);
      expect(parsed.matchedKeywords, ['Python', 'Docker', 'REST APIs']);
      expect(parsed.missingKeywords, ['AWS', 'TensorFlow']);
      expect(parsed.strengths, ['Strong Python experience']);
      expect(parsed.gaps, ['AWS is missing']);
    });
  });
}
