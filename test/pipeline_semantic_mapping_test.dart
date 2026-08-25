import 'package:flutter_test/flutter_test.dart';
import 'package:jobwink/models/resume_data.dart';

void main() {
  group('Resume Extraction & Semantic Pipeline Tests', () {
    test('1. Multi-Section Resume with Unconventional Headers and Multi-Line Entries', () {
      const rawText = '''
Nishant Arya
AI / ML Quality Engineering Specialist
nishaanttx15@gmail.com | +918102908376 | Bengaluru, India
linkedin.com/in/nishant-arya-838168321 | github.com/Nishanttxx

SUMMARY
Technical student proficient in Python, Docker, and API testing, focused on developing AI-driven test automation and intelligent quality engineering platforms.

ACADEMIC QUALIFICATIONS
B.Tech in Information Science & Engineering
NMAM Institute of Technology, Nitte
Aug 2023 – Aug 2027 | CGPA: 7.84

Class XII
Delhi Public School
2021 – 2023 | Percentage: 91.4%

Class X
St. Xavier High School
2020 – 2021 | CGPA: 9.6

CORE COMPETENCIES
Programming Languages: Python, Dart, C++, SQL
Frameworks & Libraries: Flutter, FastAPI, PyTorch, Pandas, NumPy, Pydantic
Databases & Cloud: Supabase, Firebase, PostgreSQL, MongoDB, Docker
Developer Tools: Git, GitHub, Postman, Linux, REST APIs

PROFESSIONAL JOURNEY
AI/ML Engineering Intern | 3skill | Remote
Jul 2026 – Present
• Engineered intelligent quality testing pipeline using Python and Pydantic.
• Designed automated test suites reducing regression verification time by 40%.

SELECTED WORKS & REPOSITORIES
JobWink AI Career Suite | Flutter, Supabase, Gemini API | github.com/Nishanttxx/JobWink
• Developed comprehensive full-stack ATS resume builder with real-time analytics.
• Implemented multi-provider AI pipeline supporting Gemini, OpenAI, and Cerebras.

Cloud Log Inspector | Python, Docker, FastAPI | github.com/Nishanttxx/log-inspector
• Engineered asynchronous log streaming analyzer with automated anomaly detection.

LEADERSHIP & INVOLVEMENT
Member | Finite Loop Club-NMAMIT
Aug 2024 – Aug 2025
• Collaborated with a technical community to research emerging technologies.
• Organized coding competitions and workshops for over 200 participants.
''';

      final resume = ResumeData.parseFromRawText(rawText);

      // 1. Identity & Summary
      expect(resume.fullName, equals('Nishant Arya'));
      expect(resume.email, equals('nishaanttx15@gmail.com'));
      expect(resume.phone, equals('+918102908376'));
      expect(resume.location, equals('Bengaluru, India'));
      expect(resume.linkedin, contains('nishant-arya'));
      expect(resume.github, contains('Nishanttxx'));
      expect(resume.summary, contains('Technical student proficient in Python'));

      // 2. Education - Must NOT be [in, in, in]!
      expect(resume.education.length, equals(3));
      for (final edu in resume.education) {
        expect(edu.institution, isNot(equals('in')));
        expect(edu.degree, isNot(equals('in')));
        expect(ResumeData.validateEducation(edu), isTrue);
      }
      expect(resume.education[0].institution, contains('NMAM Institute of Technology'));
      expect(resume.education[0].degree, contains('B.Tech'));
      expect(resume.education[0].gpa, contains('7.84'));

      // 3. Experience
      expect(resume.experience.length, equals(1));
      expect(resume.experience[0].company, equals('3skill'));
      expect(resume.experience[0].role, equals('AI/ML Engineering Intern'));
      expect(resume.experience[0].description.length, equals(2));

      // 4. Projects
      expect(resume.projects.length, equals(2));
      expect(resume.projects[0].name, equals('JobWink AI Career Suite'));
      expect(resume.projects[0].githubUrl, contains('JobWink'));
      expect(resume.projects[0].descriptionBullets.length, equals(2));
      expect(resume.projects[1].name, equals('Cloud Log Inspector'));

      // 5. Extracurriculars
      expect(resume.extracurriculars.length, equals(1));
      expect(resume.extracurriculars[0].organization, equals('Finite Loop Club-NMAMIT'));
      expect(resume.extracurriculars[0].activity, equals('Member'));

      // 6. Certifications - Must be empty, NOT random sentence words!
      expect(resume.certifications, isEmpty);

      // 7. Skills
      expect(resume.skills.length, greaterThanOrEqualTo(10));
      expect(resume.skills, contains('Python'));
      expect(resume.skills, contains('Flutter'));
      expect(resume.skills, contains('Docker'));
      expect(resume.skills, contains('PostgreSQL'));
    });

    test('2. Resume with Zero Experience and Valid Certifications', () {
      const rawText = '''
Alex Chen
alex.chen@mit.edu | (617) 555-0182 | Cambridge, MA
github.com/alexchen | linkedin.com/in/alexchen

PROFILE
Computer Science graduate passionate about distributed systems and cloud infrastructure.

EDUCATION
Master of Science in Computer Science
Massachusetts Institute of Technology
Sep 2022 – May 2024 | GPA: 4.0

Bachelor of Science in Electrical Engineering
UC Berkeley
Aug 2018 – May 2022 | GPA: 3.92

TECHNICAL EXPERTISE
Languages: Rust, Go, C++, Python
Cloud & Tools: Kubernetes, AWS, Terraform, Docker, gRPC

PERSONAL PROJECTS
Distributed Raft Key-Value Store | Rust, Tokio | github.com/alexchen/raft-kv
• Implemented distributed consensus algorithm with automated leader election.
• Benchmarked cluster throughput achieving 50,000 requests per second.

ACCREDITATIONS & CERTIFICATES
AWS Certified Solutions Architect Professional | Amazon Web Services | 2023
Certified Kubernetes Administrator (CKA) | Linux Foundation | 2022
''';

      final resume = ResumeData.parseFromRawText(rawText);

      expect(resume.fullName, equals('Alex Chen'));
      expect(resume.education.length, equals(2));
      expect(resume.education[0].institution, contains('Massachusetts Institute of Technology'));
      expect(resume.education[1].institution, contains('UC Berkeley'));

      expect(resume.experience, isEmpty);
      expect(resume.projects.length, equals(1));
      expect(resume.projects[0].name, equals('Distributed Raft Key-Value Store'));

      expect(resume.certifications.length, equals(2));
      expect(resume.certifications[0].activity, contains('AWS Certified Solutions Architect'));
      expect(resume.certifications[1].activity, contains('Certified Kubernetes Administrator'));
    });

    test('3. Stopword and Token Rejection Verification', () {
      expect(ResumeData.isPlaceholderValue('in'), isFalse);
      expect(ResumeData.validateEducation(const EducationEntry(institution: 'in', degree: '')), isFalse);
      expect(ResumeData.validateEducation(const EducationEntry(institution: '', degree: 'in')), isFalse);
      expect(ResumeData.validateEducation(const EducationEntry(institution: 'in', degree: 'in')), isFalse);
      expect(ResumeData.validateExperience(const ExperienceEntry(company: 'Collaborated', role: '')), isFalse);
      expect(ResumeData.validateCertification(const ExtracurricularEntry(activity: 'with')), isFalse);
      expect(ResumeData.validateCertification(const ExtracurricularEntry(activity: 'Collaborated with a technical community to research emerging technologies')), isFalse);
      expect(ResumeData.validateExtracurricular(const ExtracurricularEntry(activity: 'a')), isFalse);
    });

    test('4. JSON Schema Ingestion and Normalization Gate', () {
      final inputJson = {
        'candidate_name': 'Samantha Ray',
        'contact': {
          'email': 'samantha.ray@example.com',
          'phone': '+1-800-555-1234',
          'location': 'New York, NY',
          'linkedin': 'linkedin.com/in/samantharay',
          'github': 'github.com/samantharay'
        },
        'headline': 'Lead Cloud Security Architect',
        'professional_summary': 'Security architect specializing in DevSecOps, IAM, and zero-trust cloud network infrastructure.',
        'technical_skills': ['AWS', 'Kubernetes', 'Terraform', 'Vault', 'Python', 'Go'],
        'academic_history': [
          {
            'institution': 'Columbia University',
            'degree': 'M.S. Cybersecurity',
            'startDate': '2020',
            'endDate': '2022',
            'gpa': '3.95'
          }
        ],
        'work_history': [
          {
            'company': 'CyberShield Inc',
            'role': 'Senior Security Engineer',
            'startDate': '2022',
            'endDate': 'Present',
            'location': 'New York, NY',
            'description': [
              'Architected multi-region AWS IAM boundaries and automated guardrails.',
              'Spearheaded automated threat modeling reducing vulnerability exposure by 60%.'
            ]
          }
        ],
        'key_projects': [
          {
            'name': 'Cloud Guardrail Engine',
            'technologies': ['Go', 'AWS Lambda', 'Terraform'],
            'url': 'https://github.com/samantharay/cloud-guardrails',
            'description': [
              'Real-time policy compliance scanner for multi-tenant AWS accounts.'
            ]
          }
        ],
        'certificates': [
          {
            'title': 'Certified Information Systems Security Professional (CISSP)',
            'issuer': '(ISC)²',
            'date': '2023'
          }
        ]
      };

      final resume = ResumeData.fromJson(inputJson);

      expect(resume.fullName, equals('Samantha Ray'));
      expect(resume.email, equals('samantha.ray@example.com'));
      expect(resume.phone, equals('+1-800-555-1234'));
      expect(resume.location, equals('New York, NY'));
      expect(resume.title, equals('Lead Cloud Security Architect'));
      expect(resume.summary, contains('Security architect specializing in DevSecOps'));

      expect(resume.skills.length, equals(6));
      expect(resume.education.length, equals(1));
      expect(resume.education[0].institution, equals('Columbia University'));
      expect(resume.education[0].degree, equals('M.S. Cybersecurity'));

      expect(resume.experience.length, equals(1));
      expect(resume.experience[0].company, equals('CyberShield Inc'));
      expect(resume.experience[0].description.length, equals(2));

      expect(resume.projects.length, equals(1));
      expect(resume.projects[0].name, equals('Cloud Guardrail Engine'));
      expect(resume.projects[0].githubUrl, equals('https://github.com/samantharay/cloud-guardrails'));

      expect(resume.certifications.length, equals(1));
      expect(resume.certifications[0].activity, contains('CISSP'));
    });
  });
}
