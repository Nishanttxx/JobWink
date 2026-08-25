import 'package:flutter_test/flutter_test.dart';
import 'package:jobwink/models/resume_data.dart';

void main() {
  group('Generic Resume Parser Tests', () {
    test('Standard Technical Resume Parsing', () {
      const rawText = '''
Jane Doe
Senior Full-Stack Engineer
jane.doe@example.com | +1 555-0199 | San Francisco, CA
linkedin.com/in/janedoe | github.com/janedoe

PROFESSIONAL SUMMARY
Experienced software engineer with 6+ years building distributed cloud applications and intuitive web interfaces.

TECHNICAL SKILLS
Languages: TypeScript, Go, Python, SQL
Frameworks: React, Next.js, Node.js, Express
Cloud & DevOps: AWS, Docker, Kubernetes, CI/CD

EXPERIENCE
Senior Cloud Architect | Acme Cloud Systems | San Francisco, CA | Jan 2022 - Present
• Spearheaded migration of monolith backend to microservices running on AWS EKS.
• Reduced API latency by 45% through Redis distributed caching layer.
• Mentored 8 junior engineers across frontend and backend teams.

Full Stack Developer | Tech Innovations Inc | Austin, TX | Jun 2018 - Dec 2021
• Developed customer-facing React portals with GraphQL integrations.
• Automated deployment workflows using GitHub Actions and Terraform.

PROJECTS
CloudOps Monitor | Go, Docker, Grafana | github.com/janedoe/cloudops-monitor
• Real-time monitoring platform for Kubernetes cluster resource utilization.
• Implemented Prometheus metrics collectors handling 10k metrics/sec.

Distributed Key-Value Store | Go, Raft | github.com/janedoe/raft-kv
• High-availability distributed storage engine using the Raft consensus algorithm.

EDUCATION
Master of Science in Computer Science | Stanford University | 2016 - 2018 | GPA: 3.9
Bachelor of Science in Software Engineering | University of Texas | 2012 - 2016 | GPA: 3.85

CERTIFICATIONS
AWS Certified Solutions Architect – Professional | Amazon Web Services | 2023
Certified Kubernetes Administrator (CKA) | Cloud Native Computing Foundation | 2022

ACTIVITIES & INVOLVEMENT
Open Source Contributor | Kubernetes SIG-Network | 2021 - Present
• Contributed performance bugfixes to ingress controllers.
''';

      final resume = ResumeData.parseFromRawText(rawText);

      expect(resume.fullName, 'Jane Doe');
      expect(resume.email, 'jane.doe@example.com');
      expect(resume.phone, '+1 555-0199');
      expect(resume.linkedin, contains('linkedin.com/in/janedoe'));
      expect(resume.github, contains('github.com/janedoe'));
      expect(resume.summary.isNotEmpty, isTrue);

      // Skills
      expect(resume.skillGroups.isNotEmpty, isTrue);
      expect(resume.skills.contains('TypeScript'), isTrue);
      expect(resume.skills.contains('Go'), isTrue);

      // Experience
      expect(resume.experience.length, greaterThanOrEqualTo(2));
      expect(resume.experience[0].company, 'Acme Cloud Systems');
      expect(resume.experience[0].role, 'Senior Cloud Architect');
      expect(resume.experience[0].startDate, isNotEmpty);
      expect(resume.experience[0].description.length, greaterThanOrEqualTo(2));

      // Projects
      expect(resume.projects.length, greaterThanOrEqualTo(2));
      expect(resume.projects[0].name, 'CloudOps Monitor');
      expect(resume.projects[0].githubUrl, contains('cloudops-monitor'));
      expect(resume.projects[1].name, 'Distributed Key-Value Store');

      // Education
      expect(resume.education.length, greaterThanOrEqualTo(2));
      expect(resume.education.any((e) => e.institution.contains('Stanford')), isTrue);
      expect(resume.education.any((e) => e.institution.contains('Texas')), isTrue);

      // Certifications
      expect(resume.certifications.isNotEmpty, isTrue);
      expect(resume.certifications.any((c) => c.activity.contains('AWS Certified')), isTrue);
    });

    test('Data Science Resume with Alternative Headings', () {
      const rawText = '''
Alex Rivera
Data Science Lead
alex.rivera@datascience.io | +1 415-555-0142 | Seattle, WA
github.com/arivera | linkedin.com/in/arivera

CAREER PROFILE
Machine learning specialist focusing on natural language processing, LLM fine-tuning, and scalable data pipelines.

CORE COMPETENCIES
Machine Learning: PyTorch, Scikit-learn, HuggingFace, XGBoost
Data Engineering: Spark, Pandas, SQL, BigQuery, Airflow
Deployment: FastAPI, Docker, MLflow, AWS SageMaker

SELECTED WORK
Legal Document Summarizer | PyTorch, Transformers | github.com/arivera/legal-summarizer
• Fine-tuned Llama-3 models on legal domain corpora achieving 92% ROUGE-L score.
• Packaged inference pipeline with TensorRT-LLM reducing GPU memory footprint by 50%.

Autonomous Recommendation Engine | Spark, Redis | github.com/arivera/rec-engine
• Real-time collaborative filtering system serving 2M daily active users.

PROFESSIONAL JOURNEY
Lead ML Engineer | Quant Insights | Seattle, WA | Aug 2021 - Present
• Designed retrieval-augmented generation pipelines for enterprise search over 5M documents.
• Led cross-functional team of 5 data scientists and ML engineers.

Data Scientist | Analytics Corp | San Jose, CA | Jan 2019 - Jul 2021
• Built predictive churn models saving \$1.2M annually in recurring subscription revenue.

ACADEMIC CREDENTIALS
Ph.D. in Machine Learning | University of Washington | 2015 - 2019
B.S. in Applied Mathematics | UC Berkeley | 2011 - 2015 | GPA: 3.95

HONORS & AWARDS
Best Paper Award | ACL Workshop on Efficient NLP | 2022
Presidential Fellowship | University of Washington | 2015
''';

      final resume = ResumeData.parseFromRawText(rawText);

      expect(resume.fullName, 'Alex Rivera');
      expect(resume.title, contains('Data Science'));
      expect(resume.email, 'alex.rivera@datascience.io');
      expect(resume.summary.isNotEmpty, isTrue);

      // Verify non-standard headings were correctly classified
      expect(resume.projects.length, greaterThanOrEqualTo(2));
      expect(resume.projects[0].name, 'Legal Document Summarizer');
      expect(resume.projects[1].name, 'Autonomous Recommendation Engine');

      expect(resume.experience.length, greaterThanOrEqualTo(2));
      expect(resume.experience[0].role, 'Lead ML Engineer');
      expect(resume.experience[0].company, 'Quant Insights');

      expect(resume.education.length, greaterThanOrEqualTo(2));
      expect(resume.education.any((e) => e.degree.contains('Ph.D') || e.institution.contains('Washington')), isTrue);
    });

    test('Project and Fragment Sanitation (No broken single-word project headers)', () {
      final rawProjects = [
        ProjectEntry(
          name: 'OmniSearch AI Platform',
          type: 'Flutter, FastApi',
          githubUrl: 'https://github.com/user/omnisearch',
          descriptionBullets: [
            'Architected intelligent search system using vector embeddings.',
          ],
        ),
        ProjectEntry(
          name: 'Search',
          description: 'Engineered hybrid keyword and semantic retrieval index.',
        ),
        ProjectEntry(
          name: 'AI',
          description: 'Integrated local LLM reranking pipeline.',
        ),
        ProjectEntry(
          name: 'Engineering',
          description: 'Benchmarked queries under 100 concurrent requests.',
        ),
        ProjectEntry(
          name: 'Digest',
          description: 'Generated automated summaries of top search results.',
        ),
      ];

      final clean = ResumeData.validateAndSanitizeProjects(rawProjects);

      // All single-word fragments should be merged into OmniSearch AI Platform!
      expect(clean.length, 1);
      expect(clean[0].name, 'OmniSearch AI Platform');
      expect(clean[0].descriptionBullets.length, greaterThanOrEqualTo(4));
    });

    test('Experience Date Parsing and Extracurricular Separation', () {
      final rawExp = [
        const ExperienceEntry(
          role: 'AI/ML Intern',
          company: 'TechCorp Labs',
          location: 'Bengaluru, India',
          startDate: 'Jul 2024',
          endDate: 'Present',
          description: [
            'Implemented computer vision models for defect detection.',
            'Optimized inference latency on edge devices.',
          ],
        ),
      ];

      final cleanExp = ResumeData.validateAndSanitizeExperience(rawExp);
      expect(cleanExp.length, 1);
      expect(cleanExp[0].role, 'AI/ML Intern');
      expect(cleanExp[0].company, 'TechCorp Labs');
      expect(cleanExp[0].startDate, 'Jul 2024');
      expect(cleanExp[0].endDate, 'Present');
    });

    test('Certifications Filtering (No stray & or symbols)', () {
      final json = {
        'fullName': 'Jordan Lee',
        'email': 'jordan@example.com',
        'certifications': [
          '&',
          'AWS Certified Developer | Amazon | 2023',
          'IBM Data Science Certificate | IBM | 2022',
        ],
        'extracurriculars': [
          'Member | Finite Loop Club | 2024 - 2025',
          'Volunteer | Red Cross | 2023',
        ],
      };

      final resume = ResumeData.fromJson(json);

      expect(resume.certifications.length, 2);
      expect(resume.certifications.any((c) => c.activity == '&'), isFalse);
      expect(resume.certifications[0].activity, contains('AWS Certified'));
      expect(resume.certifications[1].activity, contains('IBM Data Science'));

      expect(resume.extracurriculars.length, 2);
      expect(resume.extracurriculars[0].activity, 'Member');
      expect(resume.extracurriculars[0].organization, 'Finite Loop Club');
    });
  });
}
