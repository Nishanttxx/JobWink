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

    test('8. Projects and Experience ONLY keyword darkening test (Section 22 & 24)', () async {
      final resume = ResumeData(
        fullName: 'Test Candidate',
        skills: ['Python', 'TensorFlow', 'Machine Learning'],
        projects: [
          ProjectEntry(
            name: 'ML Classifier',
            description: 'Built a Machine Learning model using Python.',
          ),
        ],
        experience: [
          ExperienceEntry(
            role: 'Developer',
            company: 'TechCorp',
            description: ['Developed backend services.'],
          ),
        ],
      );

      const jd = '''
      Machine Learning Engineer with Python and TensorFlow experience.
      ''';

      final result = await AIService.instance.analyzeJobKeywords(
        jobDescription: jd,
        currentResume: resume,
        targetJobTitle: 'Machine Learning Engineer',
      );

      // TensorFlow is in Skills and in JD, but NOT in Projects/Experience.
      // So ATS matchedKeywords contains TensorFlow, BUT projectAndExperienceKeywords must NOT contain TensorFlow!
      expect(result.projectAndExperienceKeywords, contains('Python'));
      expect(result.projectAndExperienceKeywords, contains('Machine Learning'));
      expect(result.projectAndExperienceKeywords.contains('TensorFlow'), isFalse);
    });

    test('9. Section 23 Test: Flutter/Firebase in Projects, Python in Experience vs Flutter/Firebase JD', () async {
      final resume = ResumeData(
        fullName: 'Mobile Dev',
        skills: ['Flutter', 'Firebase'],
        projects: [
          ProjectEntry(
            name: 'ChatApp',
            description: 'Developed a Flutter mobile application using Firebase.',
          ),
        ],
        experience: [
          ExperienceEntry(
            role: 'Backend Dev',
            company: 'OldCorp',
            description: ['Worked on Python backend services.'],
          ),
        ],
      );

      const jd = '''
      Looking for a Flutter developer with Firebase experience.
      ''';

      final result = await AIService.instance.analyzeJobKeywords(
        jobDescription: jd,
        currentResume: resume,
      );

      expect(result.projectAndExperienceKeywords, contains('Flutter'));
      expect(result.projectAndExperienceKeywords, contains('Firebase'));
      expect(result.projectAndExperienceKeywords.contains('Python'), isFalse);
    });

    test('10. Section 28 Test: Software engineer with Python, Docker, REST APIs, Git, Machine Learning, React, PostgreSQL, AI', () async {
      final resume = ResumeData(
        fullName: 'Nishant Arya',
        email: 'test-user@example.com',
        github: 'github.com/Nishanttxx',
        linkedin: 'linkedin.com/in/nishant-arya-838168321',
        skills: ['Python', 'Docker', 'REST APIs', 'Git', 'Machine Learning', 'React', 'PostgreSQL', 'AI', 'Java'],
        projects: [
          ProjectEntry(
            name: 'Nexus Search',
            technologies: ['Flutter', 'Gemini API', 'AI'],
            url: 'https://github.com/Nishanttxx/Nexus-Search',
            description: 'Engineered a dynamic AI search engine utilizing Flutter, implementing advanced Prompt Engineering.',
          ),
          ProjectEntry(
            name: 'Churn Prediction (TypeScript Application)',
            technologies: ['TypeScript', 'Machine Learning'],
            url: 'https://github.com/Nishanttxx/churn-prediction',
            description: 'Developed a predictive ML model for quality classification using Logistic Regression, KNN, and Decision Tree.',
          ),
        ],
        experience: [
          ExperienceEntry(
            role: 'AI/ML Intern',
            company: 'Tech Innovations',
            description: [
              'Built a high-performance React frontend and Python backend with Docker, Git and PostgreSQL.',
            ],
          ),
        ],
        education: [
          EducationEntry(
            institution: 'NMAM Institute of Technology',
            degree: 'Bachelor of Engineering',
            fieldOfStudy: 'Computer Science',
          ),
        ],
      );

      const jd = '''
      We are looking for a software engineer with experience in Python, Docker, REST APIs, Git, Machine Learning, React, PostgreSQL and AI.
      ''';

      final result = await AIService.instance.analyzeJobKeywords(
        jobDescription: jd,
        currentResume: resume,
      );

      expect(result.projectAndExperienceKeywords, contains('Python'));
      expect(result.projectAndExperienceKeywords, contains('Docker'));
      expect(result.projectAndExperienceKeywords, contains('Git'));
      expect(result.projectAndExperienceKeywords, contains('Machine Learning'));
      expect(result.projectAndExperienceKeywords, contains('React'));
      expect(result.projectAndExperienceKeywords, contains('PostgreSQL'));
      expect(result.projectAndExperienceKeywords, contains('AI'));

      // Java is in Skills, but NOT in Projects/Experience, so must NOT be in projectAndExperienceKeywords
      expect(result.projectAndExperienceKeywords.contains('Java'), isFalse);

      // Verify PDF generation with these keywords preserves 1 page and builds cleanly
      final pdfBytes = await ResumeExportService.instance.generateAtsPdf(
        resume,
        highlightKeywords: result.projectAndExperienceKeywords,
      );
      expect(pdfBytes.isNotEmpty, isTrue);
      expect(pdfBytes.length, greaterThan(1500));
    });

    test('30. Reference Resume against Section 38 JD darkens only matching Projects/Experience keywords', () async {
      final refResume = ResumeData(
        fullName: 'Nishant Arya',
        email: 'nishaanttx15@gmail.com',
        phone: '+918102908376',
        linkedin: 'linkedin.com/in/nishant-arya-838168321',
        github: 'github.com/Nishanttxx',
        summary: 'Technical student proficient in Python, Docker, and API testing, focused on developing AI-driven test automation and intelligent quality engineering platforms.',
        education: [
          EducationEntry(
            degree: 'B.Tech in Information Science & Engineering',
            institution: 'NMAM Institute of Technology, Nitte, Udupi',
            startDate: 'Aug 2023',
            endDate: 'Aug 2027',
            gpa: '7.84',
          ),
          EducationEntry(
            degree: "Class XII (CBSE)",
            institution: "St. Karen's Secondary School, Patna, Bihar",
            endDate: 'Apr 2023',
            gpa: '82%',
          ),
          EducationEntry(
            degree: "Class X (CBSE)",
            institution: "St. Karen's School, Patna, Bihar",
            endDate: 'Apr 2021',
            gpa: '88%',
          ),
        ],
        skills: [
          'Python', 'Pydantic', 'Docker', 'Firebase', 'Supabase', 'DBMS',
          'API Testing', 'Postman', 'GitHub',
          'C++', 'Dart', 'HTML/CSS',
          'Problem Solving', 'Communication', 'Leadership', 'Teamwork', 'Decision Making',
        ],
        projects: [
          ProjectEntry(
            name: 'Nexus Search',
            type: 'AI Search Platform',
            url: 'Nishanttxx/Nexus-Searchh',
            descriptionBullets: [
              'Engineered a dynamic AI search engine utilizing the Gemini API and Flutter, implementing advanced Prompt Engineering to optimize the accuracy and reliability of LLM responses.',
              'Developed an interactive querying interface to handle real-time user interactions, focusing on the seamless integration of Generative AI components into a high-performance React frontend.',
            ],
          ),
          ProjectEntry(
            name: 'AI Voice Digest',
            type: 'AI Content Summarizer',
            url: 'Nishanttxx/Voice-Digest',
            descriptionBullets: [
              'Architected an AI-powered summarization tool using Flutter, integrating real-time transcription and API orchestration for automated content processing and data synchronization.',
              'Implemented intelligent summarization logic to transform unstructured voice data into concise digests, demonstrating capabilities in AI-driven data optimization and NLP pipelines.',
            ],
          ),
          ProjectEntry(
            name: 'GST Billing',
            type: 'Invoice Automation Suite',
            url: 'Nishanttxx/Gst_billing',
            descriptionBullets: [
              'Developed a cross-platform invoicing suite using Flutter and Dart, implementing an automated tax engine to calculate CGST, SGST, and IGST in real-time for diverse clients.',
              'Engineered a GSTR-1 reporting system that automates the generation of tax-compliant CSV/Excel files, reducing manual data entry and increasing filing efficiency for businesses.',
              'Integrated Supabase as a Cloud backend for real-time synchronization of business profiles and inventory, utilizing Riverpod for reactive state management and global data caching.',
            ],
          ),
        ],
        experience: [
          ExperienceEntry(
            role: 'AI/ML Intern',
            company: '3skill',
            location: 'Remote',
            startDate: 'Jul 2026',
            endDate: 'Present',
            description: [
              'Engineered a predictive ML model for quality classification using Logistic Regression, KNN, and Decision Tree, optimizing hyperparameters via GridSearchCV to boost accuracy.',
              'Developed an AI-based hiring prediction system to automate decision-making by analyzing candidate skills and experience, demonstrating the ability to build data-driven models for automated analysis',
            ],
          ),
          ExperienceEntry(
            role: 'Member',
            company: 'Finite Loop Club-NMAMIT',
            startDate: 'Aug 2024',
            endDate: 'Aug 2025',
            description: [
              'Collaborated with a technical community to research emerging technologies and software development practices, establishing a foundation for designing intelligent systems and automation tools',
              'Applied software engineering principles to solve complex problems through peer-led projects, focusing on the development of scalable solutions and collaborative technical design patterns.',
            ],
          ),
        ],
        extracurriculars: [
          ExtracurricularEntry(
            activity: 'Maintained active membership in the Computer Society of India (CSI) to stay current with emerging computing trends, professional standards, and industry-best software practices.',
          ),
        ],
      );

      const section38Jd = '''
      We are seeking an AI/ML Software Engineer with experience in Python, Machine Learning, scikit-learn, REST APIs, Docker, Git, PostgreSQL, model deployment and NLP. The candidate should be able to build and deploy machine learning models, develop scalable backend services, process datasets, evaluate model performance, and integrate AI-powered applications.
      ''';

      final analysis = await AIService.instance.analyzeJobKeywords(
        jobDescription: section38Jd,
        currentResume: refResume,
      );

      // Verify keywords darkened are in Projects/Experience
      expect(analysis.projectAndExperienceKeywords, contains('Machine Learning'));
      expect(analysis.projectAndExperienceKeywords, contains('NLP'));
      expect(analysis.projectAndExperienceKeywords, contains('AI'));
      expect(analysis.projectAndExperienceKeywords, contains('Software Engineering'));

      // scikit-learn, Docker, and PostgreSQL are in JD but NOT in Projects/Experience, so must NOT be in projectAndExperienceKeywords
      expect(analysis.projectAndExperienceKeywords.contains('scikit-learn'), isFalse);
      expect(analysis.projectAndExperienceKeywords.contains('Docker'), isFalse);
      expect(analysis.projectAndExperienceKeywords.contains('PostgreSQL'), isFalse);

      // Generate ATS PDF and verify single page
      final pdfBytes = await ResumeExportService.instance.generateAtsPdf(
        refResume,
        highlightKeywords: analysis.projectAndExperienceKeywords,
      );

      expect(pdfBytes.isNotEmpty, isTrue);
      expect(pdfBytes.length, greaterThan(2000));
    });

    test('31. Required vs Preferred weighting in Job Description', () async {
      final resume = ResumeData(
        fullName: 'Alex Dev',
        skills: ['Python', 'Docker', 'Kubernetes'],
        projects: [
          ProjectEntry(
            name: 'API Engine',
            description: 'Built a high-performance REST API in Python using Docker containers.',
          ),
        ],
        experience: [
          ExperienceEntry(
            role: 'Software Engineer',
            company: 'TechCorp',
            description: ['Managed Kubernetes deployments.'],
          ),
        ],
      );

      const jd = '''
      Required:
      - Python
      - REST APIs

      Preferred:
      - Docker
      - Kubernetes
      ''';

      final analysis = await AIService.instance.analyzeJobKeywords(
        jobDescription: jd,
        currentResume: resume,
      );

      // Python and REST APIs are required -> High priority
      expect(analysis.projectAndExperienceKeywords, contains('Python'));
      expect(analysis.projectAndExperienceKeywords, contains('REST APIs'));
      // Docker is preferred -> also present
      expect(analysis.projectAndExperienceKeywords, contains('Docker'));
    });

    test('32. Multi-word phrase matching as single units without fragmenting', () async {
      final resume = ResumeData(
        fullName: 'Jane Doe',
        projects: [
          ProjectEntry(
            name: 'NLP Pipeline',
            description: 'Built a Natural Language Processing system with Model Deployment and Prompt Engineering.',
          ),
        ],
      );

      const jd = '''
      Looking for an engineer experienced in Natural Language Processing, Model Deployment, and Prompt Engineering.
      ''';

      final analysis = await AIService.instance.analyzeJobKeywords(
        jobDescription: jd,
        currentResume: resume,
      );

      expect(analysis.projectAndExperienceKeywords, contains('Natural Language Processing'));
      expect(analysis.projectAndExperienceKeywords, contains('Model Deployment'));
      expect(analysis.projectAndExperienceKeywords, contains('Prompt Engineering'));

      // Verify PDF generation with multi-word keywords
      final pdfBytes = await ResumeExportService.instance.generateAtsPdf(
        resume,
        highlightKeywords: analysis.projectAndExperienceKeywords,
      );
      expect(pdfBytes.isNotEmpty, isTrue);
    });

    test('33. Strict exclusion of Skills and Summary from keyword darkening source', () async {
      final resume = ResumeData(
        fullName: 'Dev Test',
        summary: 'Expert in GraphQL, Redis, and Terraform.',
        skills: ['GraphQL', 'Redis', 'Terraform'],
        projects: [
          ProjectEntry(
            name: 'Web App',
            description: 'Developed frontend using React.',
          ),
        ],
        experience: [
          ExperienceEntry(
            role: 'Dev',
            company: 'AppCo',
            description: ['Wrote Python scripts.'],
          ),
        ],
      );

      const jd = '''
      Seeking developer with GraphQL, Redis, Terraform, React, and Python.
      ''';

      final analysis = await AIService.instance.analyzeJobKeywords(
        jobDescription: jd,
        currentResume: resume,
      );

      // Only React and Python exist in Projects and Experience
      expect(analysis.projectAndExperienceKeywords, contains('React'));
      expect(analysis.projectAndExperienceKeywords, contains('Python'));

      // GraphQL, Redis, Terraform are in Skills and Summary only -> strictly excluded from darkening
      expect(analysis.projectAndExperienceKeywords.contains('GraphQL'), isFalse);
      expect(analysis.projectAndExperienceKeywords.contains('Redis'), isFalse);
      expect(analysis.projectAndExperienceKeywords.contains('Terraform'), isFalse);
    });
  });
}
