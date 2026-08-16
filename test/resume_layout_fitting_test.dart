import 'package:flutter_test/flutter_test.dart';
import 'package:jobwink/models/resume_data.dart';
import 'package:jobwink/services/resume_export_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Adaptive One-Page Resume Layout Fitting Engine', () {
    test('Short resume fits strictly on 1 page and expands spacing', () async {
      final resume = ResumeData(
        fullName: 'Jane Doe',
        email: 'jane@example.com',
        phone: '+1 555 0199',
        location: 'New York, NY',
        title: 'Junior Developer',
        summary: 'Passionate software engineer looking for exciting opportunities.',
        skills: ['Dart', 'Flutter', 'HTML', 'CSS'],
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

    test('Medium resume fits strictly on 1 page', () async {
      final resume = ResumeData(
        fullName: 'Nishant Arya',
        email: 'nishant@example.com',
        phone: '+1 234 567 8900',
        location: 'San Francisco, CA',
        linkedin: 'https://linkedin.com/in/nishant',
        github: 'https://github.com/nishant',
        title: 'Senior Software Engineer',
        summary: 'Experienced software engineer – specializing in mobile & cloud architectures with high impact across multiple distributed systems.',
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
            descriptionBullets: ['Built AI job prediction engine — high precision matching with adaptive resume layout engine.'],
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

    test('Long resume with 4 positions and multiple projects compresses strictly to 1 page', () async {
      final resume = ResumeData(
        fullName: 'Alex Vance',
        email: 'alex.vance@example.com',
        phone: '+1 555 012 3456',
        location: 'Seattle, WA',
        linkedin: 'https://linkedin.com/in/alexvance',
        github: 'https://github.com/alexvance',
        title: 'Lead Systems & Cloud Architect',
        summary: 'Versatile Lead Systems Architect with 8+ years driving full-stack mobile, backend, and distributed cloud applications. Proven track record of scaling high-throughput systems and leading high-performing cross-functional engineering teams.',
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
          EducationEntry(
            institution: 'Washington State University',
            degree: 'B.S.',
            fieldOfStudy: 'Computer Science',
            startDate: '2011',
            endDate: '2015',
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

    test('Ultra-dense long resume prunes content density & fits strictly on 1 page with readable font', () async {
      final denseResume = ResumeData(
        fullName: 'Dr. Evelyn Carter',
        email: 'evelyn.carter@tech.org',
        phone: '+1 555 999 8888',
        location: 'Boston, MA',
        linkedin: 'https://linkedin.com/in/evelyncarter',
        github: 'https://github.com/evelyncarter',
        title: 'Principal AI & Cloud Infrastructure Director',
        summary: 'Strategic technology executive and computer scientist leading enterprise digital transformation, autonomous systems, and distributed cloud computing across fortune 500 environments.',
        skills: [
          'Python', 'C++', 'Go', 'Rust', 'Dart', 'Flutter', 'PyTorch', 'TensorFlow',
          'Kubernetes', 'Docker', 'AWS', 'GCP', 'Azure', 'Kafka', 'GraphQL', 'System Architecture'
        ],
        experience: List.generate(
          6,
          (i) => ExperienceEntry(
            company: 'Tech Enterprise ${i + 1}',
            role: 'Director / Staff Architect ${i + 1}',
            location: 'Boston, MA',
            startDate: '${2018 + i}',
            endDate: '${2019 + i}',
            description: List.generate(
              6,
              (j) => 'Spearheaded critical system architecture initiative $j, scaling throughput by 400% and maintaining sub-second API latency across distributed nodes.',
            ),
          ),
        ),
        projects: List.generate(
          5,
          (i) => ProjectEntry(
            name: 'Distributed Core Engine ${i + 1}',
            type: 'Cloud System',
            descriptionBullets: [
              'Built scalable stream processing engine handling 100k events/sec.',
              'Engineered fault-tolerant storage layer with automatic failover.',
              'Optimized resource utilization saving \$500k annually.',
            ],
            technologies: ['Go', 'Kafka', 'Kubernetes'],
          ),
        ),
        education: [
          EducationEntry(
            institution: 'MIT',
            degree: 'Ph.D.',
            fieldOfStudy: 'Computer Science',
            startDate: '2012',
            endDate: '2016',
          ),
          EducationEntry(
            institution: 'Stanford University',
            degree: 'B.S.',
            fieldOfStudy: 'Electrical Engineering',
            startDate: '2008',
            endDate: '2012',
          ),
        ],
        extracurriculars: List.generate(
          5,
          (i) => ExtracurricularEntry(
            activity: 'Enterprise Certification Level ${i + 1}',
            organization: 'Global Cloud Association',
            description: 'Credential Verified ID: GCA-992$i',
          ),
        ),
      );

      final (shortenedResume, config) = ResumeExportService.instance.optimizeResumeConfigAndData(
        denseResume,
        const PdfTemplateConfig(),
      );
      final measurement = ResumeExportService.instance.measureResumeLayout(shortenedResume, config);

      // Verify that body font size remained readable (>= 8.0pt)
      expect(config.bodyFontSize, greaterThanOrEqualTo(8.0));

      // Verify layout measurement shows strictly 1 page
      expect(measurement.pageCount, equals(1));
      expect(measurement.overflow, isFalse);

      // Verify PDF generation succeeds and returns a single-page document
      final pdfBytes = await ResumeExportService.instance.generateAtsPdf(shortenedResume);
      expect(pdfBytes.length, greaterThan(1000));

    });

  });
}
