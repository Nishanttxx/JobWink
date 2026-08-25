import 'package:flutter_test/flutter_test.dart';
import 'package:jobwink/models/resume_data.dart';
import 'package:jobwink/services/resume_export_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Adaptive Strict One-Page Resume Layout Fitting Engine', () {
    // 1. Short resume
    test('1. Short resume fits strictly on 1 page with increased typography/spacing', () async {
      final resume = ResumeData(
        fullName: 'Jane Doe',
        email: 'jane@example.com',
        phone: '+1 555 0199',
        location: 'New York, NY',
        title: 'Junior Developer',
        summary: 'Passionate software engineer looking for exciting opportunities in modern application development.',
        skills: ['Dart', 'Flutter', 'HTML', 'CSS', 'JavaScript'],
        experience: [
          ExperienceEntry(
            company: 'Acme Software',
            role: 'Intern',
            location: 'New York, NY',
            startDate: '2023',
            endDate: '2024',
            description: ['Assisted in frontend widget development and unit testing.'],
          ),
        ],
        education: [
          EducationEntry(
            institution: 'State University',
            degree: 'B.S.',
            fieldOfStudy: 'Computer Science',
            startDate: '2019',
            endDate: '2023',
          ),
        ],
      );

      final config = ResumeExportService.instance.optimizeResumeConfig(
        resume,
        const PdfTemplateConfig(),
      );
      final measurement = ResumeExportService.instance.measureResumeLayout(resume, config);

      expect(measurement.pageCount, equals(1));
      expect(measurement.overflow, isFalse);

      final pdfBytes = await ResumeExportService.instance.generateAtsPdf(resume);
      expect(pdfBytes.length, greaterThan(1000));
    });

    // 2. Medium resume
    test('2. Medium resume fits strictly on 1 page', () async {
      final resume = ResumeData(
        fullName: 'Nishant Arya',
        email: 'nishant@example.com',
        phone: '+1 234 567 8900',
        location: 'San Francisco, CA',
        linkedin: 'https://linkedin.com/in/nishant',
        github: 'https://github.com/nishant',
        title: 'Senior Software Engineer',
        summary: 'Experienced software engineer specializing in mobile & cloud architectures with high impact across multiple distributed systems.',
        skills: ['Flutter', 'Dart', 'Python', 'FastAPI', 'PostgreSQL', 'Docker', 'Kubernetes', 'AWS'],
        experience: [
          ExperienceEntry(
            company: 'Tech Corp — Global',
            role: 'Senior Engineer',
            location: 'San Francisco, CA',
            startDate: '2022',
            endDate: 'Present',
            description: [
              'Led development of core features using Flutter rich graphics pipeline and state management.',
              'Reduced end-to-end API response latency by 40% across microservices.',
              'Mentored junior engineers and spearheaded automated testing standardizations.',
            ],
          ),
          ExperienceEntry(
            company: 'Innovate Labs',
            role: 'Software Engineer',
            location: 'San Jose, CA',
            startDate: '2020',
            endDate: '2022',
            description: [
              'Architected backend services handling over 1 million daily requests.',
              'Integrated payment gateways and real-time notification streams.',
            ],
          ),
        ],
        projects: [
          ProjectEntry(
            name: 'JobWink Editor',
            type: 'Mobile App',
            descriptionBullets: ['Built AI job prediction engine with adaptive resume layout engine.'],
            technologies: ['Flutter', 'Python', 'FastAPI'],
          ),
        ],
        education: [
          EducationEntry(
            institution: 'University of Technology',
            degree: 'B.S.',
            fieldOfStudy: 'Computer Science',
            startDate: '2016',
            endDate: '2020',
          ),
        ],
      );

      final config = ResumeExportService.instance.optimizeResumeConfig(
        resume,
        const PdfTemplateConfig(),
      );
      final measurement = ResumeExportService.instance.measureResumeLayout(resume, config);

      expect(measurement.pageCount, equals(1));
      expect(measurement.overflow, isFalse);

      final pdfBytes = await ResumeExportService.instance.generateAtsPdf(resume);
      expect(pdfBytes.length, greaterThan(1000));
    });

    // 3. Long resume
    test('3. Long resume with 3 roles and 3 projects compresses strictly to 1 page', () async {
      final resume = ResumeData(
        fullName: 'Alex Vance',
        email: 'alex.vance@example.com',
        phone: '+1 555 012 3456',
        location: 'Seattle, WA',
        linkedin: 'https://linkedin.com/in/alexvance',
        github: 'https://github.com/alexvance',
        title: 'Lead Systems & Cloud Architect',
        summary: 'Versatile Lead Systems Architect with 8+ years driving full-stack mobile, backend, and distributed cloud applications. Proven track record of scaling high-throughput systems and leading engineering teams.',
        skills: ['Dart', 'Flutter', 'Python', 'TypeScript', 'Node.js', 'Go', 'AWS', 'GCP', 'Kubernetes', 'Docker', 'GraphQL', 'REST API', 'Redis', 'PostgreSQL', 'CI/CD'],
        experience: [
          ExperienceEntry(
            company: 'CloudScale Inc.',
            role: 'Lead Architect',
            location: 'Seattle, WA',
            startDate: '2022',
            endDate: 'Present',
            description: [
              'Spearheaded enterprise cloud migration reducing infrastructure cost by 35% annually across 12 region deployments.',
              'Designed resilience patterns and automated recovery workflows ensuring 99.99% service availability.',
              'Engineered custom state management libraries utilized by 50+ internal developers.',
              'Optimized DB queries and connection pooling, boosting query execution performance by 60%.',
            ],
          ),
          ExperienceEntry(
            company: 'DataStream Systems',
            role: 'Senior Staff Engineer',
            location: 'Bellevue, WA',
            startDate: '2019',
            endDate: '2022',
            description: [
              'Built real-time telemetry streaming pipeline processing over 50,000 events per second with sub-10ms latency.',
              'Implemented end-to-end security compliance and OAuth2 / OIDC authentication protocols.',
              'Architected cross-platform mobile client application using Flutter with offline-first synchronization.',
            ],
          ),
          ExperienceEntry(
            company: 'NextGen Solutions',
            role: 'Software Engineer',
            location: 'Redmond, WA',
            startDate: '2017',
            endDate: '2019',
            description: [
              'Developed modular UI component library improving frontend design system compliance.',
              'Collaborated closely with product teams to deliver 15+ major feature releases on schedule.',
            ],
          ),
        ],
        projects: [
          ProjectEntry(
            name: 'Enterprise Telemetry Hub',
            type: 'Cloud Platform',
            descriptionBullets: [
              'High-speed streaming log engine built with Go and Kafka.',
              'Integrated live anomaly detection algorithms notifying ops teams instantly.',
            ],
            technologies: ['Go', 'Kafka', 'Docker', 'Kubernetes'],
          ),
          ProjectEntry(
            name: 'Adaptive UI Framework',
            type: 'Open Source',
            descriptionBullets: [
              'Cross-platform layout fitting engine designed for multi-screen responsive environments.',
            ],
            technologies: ['Flutter', 'Dart'],
          ),
        ],
        education: [
          EducationEntry(
            institution: 'University of Washington',
            degree: 'M.S.',
            fieldOfStudy: 'Software Engineering',
            startDate: '2015',
            endDate: '2017',
          ),
        ],
        extracurriculars: [
          ExtracurricularEntry(
            activity: 'AWS Certified Solutions Architect — Professional',
            organization: 'Amazon Web Services',
            description: 'Credential Id: AWS-PAS-98231',
          ),
        ],
      );

      final config = ResumeExportService.instance.optimizeResumeConfig(
        resume,
        const PdfTemplateConfig(),
      );
      final measurement = ResumeExportService.instance.measureResumeLayout(resume, config);

      expect(measurement.pageCount, equals(1));
      expect(measurement.overflow, isFalse);

      final pdfBytes = await ResumeExportService.instance.generateAtsPdf(resume);
      expect(pdfBytes.length, greaterThan(1000));
    });

    // 4. Resume with many projects
    test('4. Resume with 5 projects fits strictly on 1 page', () async {
      final resume = ResumeData(
        fullName: 'Marcus Brody',
        email: 'marcus@brody.dev',
        phone: '+1 415 555 2671',
        location: 'Austin, TX',
        title: 'Full Stack Engineer',
        summary: 'Full stack engineer with a prolific portfolio of production web and mobile software projects.',
        skills: ['React', 'Node.js', 'Flutter', 'PostgreSQL', 'AWS', 'TypeScript'],
        experience: [
          ExperienceEntry(
            company: 'Vanguard Tech',
            role: 'Full Stack Engineer',
            location: 'Austin, TX',
            startDate: '2021',
            endDate: 'Present',
            description: ['Built user-facing workflow features and automated deployment pipelines.'],
          ),
        ],
        projects: List.generate(
          5,
          (i) => ProjectEntry(
            name: 'Software Project ${i + 1}',
            type: 'Production App',
            descriptionBullets: [
              'Designed responsive layout with continuous integration testing.',
              'Deployed multi-tenant backend on scalable cloud infrastructure.',
            ],
            technologies: ['TypeScript', 'Flutter', 'Docker'],
          ),
        ),
        education: [
          EducationEntry(
            institution: 'UT Austin',
            degree: 'B.S.',
            fieldOfStudy: 'Computer Science',
            startDate: '2017',
            endDate: '2021',
          ),
        ],
      );

      final config = ResumeExportService.instance.optimizeResumeConfig(
        resume,
        const PdfTemplateConfig(),
      );
      final measurement = ResumeExportService.instance.measureResumeLayout(resume, config);

      expect(measurement.pageCount, equals(1));
      expect(measurement.overflow, isFalse);

      final pdfBytes = await ResumeExportService.instance.generateAtsPdf(resume);
      expect(pdfBytes.length, greaterThan(1000));
    });

    // 5. Resume with many experience bullets
    test('5. Resume with many experience bullets fits strictly on 1 page', () async {
      final resume = ResumeData(
        fullName: 'Elena Rostova',
        email: 'elena@rostova.com',
        phone: '+1 212 555 7890',
        location: 'New York, NY',
        title: 'Staff Backend Architect',
        summary: 'Specialized in microservice event-driven architecture and high transaction distributed data systems.',
        skills: ['Java', 'Spring Boot', 'Kafka', 'PostgreSQL', 'Redis', 'Kubernetes'],
        experience: [
          ExperienceEntry(
            company: 'Global Financial Technologies',
            role: 'Staff Architect',
            location: 'New York, NY',
            startDate: '2020',
            endDate: 'Present',
            description: [
              'Architected high-frequency trading message routing handling 250k msgs/sec with zero packet drop.',
              'Reduced p99 database transaction latency from 45ms down to 8ms using distributed cache clustering.',
              'Spearheaded multi-region disaster recovery replication protocol compliant with financial regulatory bodies.',
              'Refactored legacy monolith into 14 domain-driven microservices with continuous canary deployments.',
              'Authored internal technical specifications and mentored 12 senior engineering team members.',
              'Integrated automated fault injection testing into CI pipelines ensuring system resilience under load.',
            ],
          ),
        ],
        education: [
          EducationEntry(
            institution: 'Columbia University',
            degree: 'M.S.',
            fieldOfStudy: 'Computer Engineering',
            startDate: '2018',
            endDate: '2020',
          ),
        ],
      );

      final config = ResumeExportService.instance.optimizeResumeConfig(
        resume,
        const PdfTemplateConfig(),
      );
      final measurement = ResumeExportService.instance.measureResumeLayout(resume, config);

      expect(measurement.pageCount, equals(1));
      expect(measurement.overflow, isFalse);

      final pdfBytes = await ResumeExportService.instance.generateAtsPdf(resume);
      expect(pdfBytes.length, greaterThan(1000));
    });

    // 6. Resume with long education entries
    test('6. Resume with multiple detailed education entries fits strictly on 1 page', () async {
      final resume = ResumeData(
        fullName: 'David K. Miller',
        email: 'david.miller@alumni.edu',
        phone: '+1 617 555 3344',
        location: 'Cambridge, MA',
        title: 'Research Scientist & Software Engineer',
        summary: 'Applied researcher and software engineer focusing on numerical algorithms and machine learning systems.',
        skills: ['Python', 'C++', 'PyTorch', 'Linear Algebra', 'Distributed Systems'],
        experience: [
          ExperienceEntry(
            company: 'Applied AI Labs',
            role: 'Research Scientist',
            location: 'Cambridge, MA',
            startDate: '2022',
            endDate: 'Present',
            description: ['Developed optimized transformer inference kernels for edge computing devices.'],
          ),
        ],
        education: [
          EducationEntry(
            institution: 'Massachusetts Institute of Technology',
            degree: 'Ph.D.',
            fieldOfStudy: 'Electrical Engineering & Computer Science',
            startDate: '2018',
            endDate: '2022',
            gpa: '4.0',
          ),
          EducationEntry(
            institution: 'Stanford University',
            degree: 'M.S.',
            fieldOfStudy: 'Computer Science',
            startDate: '2016',
            endDate: '2018',
            gpa: '3.95',
          ),
          EducationEntry(
            institution: 'University of California, Berkeley',
            degree: 'B.S.',
            fieldOfStudy: 'EECS',
            startDate: '2012',
            endDate: '2016',
            gpa: '3.92',
          ),
        ],
      );

      final config = ResumeExportService.instance.optimizeResumeConfig(
        resume,
        const PdfTemplateConfig(),
      );
      final measurement = ResumeExportService.instance.measureResumeLayout(resume, config);

      expect(measurement.pageCount, equals(1));
      expect(measurement.overflow, isFalse);

      final pdfBytes = await ResumeExportService.instance.generateAtsPdf(resume);
      expect(pdfBytes.length, greaterThan(1000));
    });

    // 7. Resume with long skills
    test('7. Resume with extensive categorized skills fits strictly on 1 page', () async {
      final resume = ResumeData(
        fullName: 'Sophia Chen',
        email: 'sophia.chen@dev.io',
        phone: '+1 408 555 9182',
        location: 'San Jose, CA',
        title: 'Principal Cloud & DevOps Architect',
        summary: 'Cloud infrastructure expert with broad multi-cloud and security domain competencies.',
        skills: [
          'Python', 'Go', 'Rust', 'TypeScript', 'Dart', 'Flutter', 'React', 'Node.js',
          'Kubernetes', 'Docker', 'Terraform', 'Ansible', 'Helm', 'ArgoCD', 'Prometheus',
          'Grafana', 'AWS Lambda', 'AWS ECS', 'GCP GKE', 'Azure AKS', 'PostgreSQL', 'Redis',
          'Kafka', 'Elasticsearch', 'GraphQL', 'gRPC', 'OAuth2', 'Zero Trust Architecture'
        ],
        experience: [
          ExperienceEntry(
            company: 'Cloud Innovators',
            role: 'Principal Architect',
            location: 'San Jose, CA',
            startDate: '2021',
            endDate: 'Present',
            description: ['Managed multi-cloud governance and automated infrastructure provisioning.'],
          ),
        ],
        education: [
          EducationEntry(
            institution: 'San Jose State University',
            degree: 'B.S.',
            fieldOfStudy: 'Software Engineering',
            startDate: '2017',
            endDate: '2021',
          ),
        ],
      );

      final config = ResumeExportService.instance.optimizeResumeConfig(
        resume,
        const PdfTemplateConfig(),
      );
      final measurement = ResumeExportService.instance.measureResumeLayout(resume, config);

      expect(measurement.pageCount, equals(1));
      expect(measurement.overflow, isFalse);

      final pdfBytes = await ResumeExportService.instance.generateAtsPdf(resume);
      expect(pdfBytes.length, greaterThan(1000));
    });

    // 8. Resume with all sections populated
    test('8. Resume with all sections fully populated fits strictly on 1 page', () async {
      final resume = ResumeData(
        fullName: 'Jordan Michael Lee',
        email: 'jordan.lee@example.com',
        phone: '+1 312 555 4488',
        location: 'Chicago, IL',
        linkedin: 'https://linkedin.com/in/jordanmlee',
        github: 'https://github.com/jordanmlee',
        title: 'Staff Software Engineer',
        summary: 'Comprehensive software engineer with end-to-end expertise spanning mobile UI, backend microservices, data pipelines, and team mentorship.',
        skills: ['Flutter', 'Dart', 'Kotlin', 'Swift', 'Node.js', 'PostgreSQL', 'Docker', 'AWS'],
        experience: [
          ExperienceEntry(
            company: 'Apex Digital Solutions',
            role: 'Lead Mobile Engineer',
            location: 'Chicago, IL',
            startDate: '2022',
            endDate: 'Present',
            description: [
              'Architected modular cross-platform mobile client serving 500k active users.',
              'Integrated biometric authentication, real-time push notifications, and offline cache sync.',
            ],
          ),
          ExperienceEntry(
            company: 'Midwest Software Labs',
            role: 'Software Engineer',
            location: 'Chicago, IL',
            startDate: '2019',
            endDate: '2022',
            description: [
              'Developed RESTful microservices and integrated payment gateways with Stripe.',
            ],
          ),
        ],
        projects: [
          ProjectEntry(
            name: 'Pulse Healthcare App',
            type: 'Mobile Application',
            descriptionBullets: ['HIPAA-compliant telemedicine consultation app with WebRTC video calling.'],
            technologies: ['Flutter', 'WebRTC', 'Firebase'],
          ),
          ProjectEntry(
            name: 'OpenMetrics Dashboard',
            type: 'Analytics Platform',
            descriptionBullets: ['Real-time performance metrics visualizer for distributed servers.'],
            technologies: ['React', 'Go', 'Prometheus'],
          ),
        ],
        education: [
          EducationEntry(
            institution: 'University of Illinois Urbana-Champaign',
            degree: 'B.S.',
            fieldOfStudy: 'Computer Science',
            startDate: '2015',
            endDate: '2019',
          ),
        ],
        certifications: [
          ExtracurricularEntry(
            activity: 'AWS Certified Developer — Associate',
            organization: 'Amazon Web Services',
            description: 'Validation ID: AWS-DEV-77821',
          ),
        ],
        extracurriculars: [
          ExtracurricularEntry(
            activity: 'Hackathon Grand Prize Winner',
            organization: 'Midwest Tech Summit 2023',
            description: 'Built automated disaster response tracking tool in 48 hours.',
          ),
        ],
      );

      final config = ResumeExportService.instance.optimizeResumeConfig(
        resume,
        const PdfTemplateConfig(),
      );
      final measurement = ResumeExportService.instance.measureResumeLayout(resume, config);

      expect(measurement.pageCount, equals(1));
      expect(measurement.overflow, isFalse);

      final pdfBytes = await ResumeExportService.instance.generateAtsPdf(resume);
      expect(pdfBytes.length, greaterThan(1000));
    });
  });
}
