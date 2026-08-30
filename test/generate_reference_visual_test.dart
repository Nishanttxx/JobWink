import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobwink/models/resume_data.dart';
import 'package:jobwink/models/resume_type.dart';
import 'package:jobwink/services/resume_export_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Generate full Nishant Arya ATS PDF and verify one-page output', () async {
    final resume = ResumeData(
      fullName: 'Nishant Arya',
      email: 'test-user@example.com',
      phone: '+91 8088031526',
      location: 'Nitte, Karkala, Karnataka - 574110',
      linkedin: 'https://linkedin.com/in/nishant-arya-b40b7921a/',
      github: 'https://github.com/Nishanttxx',
      summary: '',
      skills: [
        'Flutter', 'Dart', 'Python', 'React', 'FastAPI', 'Node.js', 'PostgreSQL',
        'Supabase', 'Docker', 'Git', 'Machine Learning', 'Generative AI',
      ],
      education: [
        EducationEntry(
          institution: 'NMAM Institute of Technology, Nitte',
          degree: 'B.Tech in Artificial Intelligence & Machine Learning',
          fieldOfStudy: 'AIML',
          startDate: 'Nov 2022',
          endDate: 'June 2026',
          gpa: 'CGPA: 8.7',
        ),
      ],
      experience: [
        ExperienceEntry(
          company: '3skill',
          role: 'AI / ML Engineer',
          location: 'Remote',
          startDate: 'July 2024',
          endDate: 'Present',
          description: [
            'Engineered a predictive ML model for quality classification using Logistic Regression, KNN, and Decision Tree, optimizing hyperparameters via GridSearchCV to boost accuracy.',
            'Developed an AI-based hiring prediction system with automated analysis and machine learning pipeline, accelerating candidate screening and improving evaluation consistency.',
            'Architected intelligent systems and automation tools using Python and REST APIs, optimizing end-to-end performance and streamlining internal workflows.',
            'Collaborated with cross-functional teams on collaborative technical design to build scalable solutions that align with business and operational objectives.',
          ],
        ),
      ],
      projects: [
        ProjectEntry(
          name: 'Nexus Search',
          type: 'AI Platform',
          url: 'https://github.com/Nishanttxx/nexus_search',
          descriptionBullets: [
            'Engineered a dynamic AI search engine utilizing the Gemini API and Flutter, implementing advanced Prompt Engineering to optimize the accuracy and reliability of LLM responses.',
            'Developed an interactive querying interface to handle real-time user interactions, focusing on the seamless integration of Generative AI components into a high-performance React frontend.',
            'Architected scalable backend services using Flutter, ensuring responsive performance and efficient API orchestration across multi-source data retrieval pipelines.',
            'Applied AI-driven data optimization techniques to process datasets dynamically, improving relevance and reducing latency across diverse natural language queries.',
          ],
        ),
        ProjectEntry(
          name: 'Vyapar Bandhu',
          type: 'Business Platform',
          url: 'https://github.com/Nishanttxx/Vyapar_Bandhu',
          descriptionBullets: [
            'Engineered an automated tax engine using Flutter and Dart, accurately calculating CGST, SGST, and IGST to ensure full compliance with regional Indian GST regulations.',
            'Developed an integrated compliance tool enabling instant generation and direct export of official GSTR-1 reports into CSV/Excel formats.',
            'Integrated Supabase as a Cloud backend for real-time synchronization of business profiles and inventory, utilizing Riverpod for reactive state management and global data caching.',
          ],
        ),
      ],
      certifications: [
        ExtracurricularEntry(
          activity: 'Postman API Fundamentals Student Expert',
          organization: 'Postman',
          role: '',
          url: 'https://badgr.com/public/assertions/9fG3i4v7ST6E4p_R_o2Z1w',
          description: 'Demonstrated proficiency in API basics, requests, testing, and automation workflows.',
        ),
      ],
      extracurriculars: [
        ExtracurricularEntry(
          activity: 'Core Member, Tantra Club',
          organization: 'NMAMIT',
          role: 'Technical Team',
          description: 'Organized and mentored workshops on emerging technologies, fostering peer-led learning.',
        ),
      ],
    );

    const jd = 'Looking for an AI/ML Engineer with Python, Flutter, React, Gemini API, Generative AI, Machine Learning, Supabase, and REST APIs.';

    final pdfBytes = await ResumeExportService.instance.generateAtsPdf(
      resume,
      selectedResumeType: ResumeType.fresher,
      jobDescription: jd,
    );

    expect(pdfBytes, isNotNull);
    expect(pdfBytes.length, greaterThan(2000));

    // Save to portable temporary test output directory for visual inspection
    final outDir = Directory('${Directory.systemTemp.path}/jobwink_test_output');
    if (!outDir.existsSync()) {
      outDir.createSync(recursive: true);
    }
    final file = File('${outDir.path}/generated_test_resume.pdf');
    await file.writeAsBytes(pdfBytes);
    expect(file.existsSync(), isTrue);
  });
}
