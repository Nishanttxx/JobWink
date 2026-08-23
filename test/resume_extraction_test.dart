import 'package:flutter_test/flutter_test.dart';
import 'package:jobwink/models/resume_data.dart';

void main() {
  group('Resume Extraction & Section Mapping Unit Tests', () {
    test('Parses complete candidate resume JSON into ResumeData with 100% field retention', () {
      final sampleJson = {
        "fullName": "Nishant Arya",
        "email": "nishant@example.com",
        "phone": "+1 234 567 8900",
        "location": "San Francisco, CA",
        "linkedin": "https://linkedin.com/in/nishant-arya",
        "github": "https://github.com/nishant-arya",
        "title": "Senior Software Engineer",
        "summary": "Experienced engineer specializing in Flutter and AI system design.",
        "skills": ["Flutter", "Dart", "Python", "REST API", "Docker"],
        "experience": [
          {
            "company": "Tech Corp",
            "role": "Senior Engineer",
            "startDate": "Jan 2022",
            "endDate": "Present",
            "description": [
              "Led mobile application development using Flutter",
              "Architected AI extraction pipeline for resumes"
            ]
          }
        ],
        "education": [
          {
            "institution": "Stanford University",
            "degree": "Bachelor of Science",
            "fieldOfStudy": "Computer Science",
            "startDate": "2018",
            "endDate": "2022",
            "gpa": "3.9"
          }
        ],
        "projects": [
          {
            "name": "JobWink Platform",
            "description": [
              "AI-powered job matching and resume builder platform",
              "Implemented multi-provider LLM fallback system"
            ],
            "technologies": ["Flutter", "Supabase", "Gemini API"],
            "url": "https://github.com/nishant-arya/jobwink"
          }
        ],
        "certifications": [
          {
            "name": "AWS Certified Solutions Architect",
            "issuer": "Amazon Web Services",
            "date": "2023"
          }
        ]
      };

      final resume = ResumeData.fromJson(sampleJson);

      expect(resume.hasUsableData, isTrue);
      expect(resume.fullName, equals("Nishant Arya"));
      expect(resume.email, equals("nishant@example.com"));
      expect(resume.phone, equals("+1 234 567 8900"));
      expect(resume.location, equals("San Francisco, CA"));
      expect(resume.linkedin, equals("https://linkedin.com/in/nishant-arya"));
      expect(resume.github, equals("https://github.com/nishant-arya"));
      expect(resume.title, equals("Senior Software Engineer"));
      expect(resume.summary, contains("Experienced engineer"));

      expect(resume.skills.length, equals(5));
      expect(resume.skills, containsAll(["Flutter", "Dart", "Python", "REST API", "Docker"]));

      expect(resume.experience.length, equals(1));
      final exp = resume.experience.first;
      expect(exp.company, equals("Tech Corp"));
      expect(exp.role, equals("Senior Engineer"));
      expect(exp.description.length, equals(2));

      expect(resume.education.length, equals(1));
      final edu = resume.education.first;
      expect(edu.institution, equals("Stanford University"));
      expect(edu.degree, equals("Bachelor of Science"));
      expect(edu.fieldOfStudy, equals("Computer Science"));

      expect(resume.projects.length, equals(1));
      final proj = resume.projects.first;
      expect(proj.name, equals("JobWink Platform"));
      expect(proj.effectiveBullets.length, equals(2));
      expect(proj.technologies, contains("Flutter"));

      expect(resume.certifications.length, equals(1));
      expect(resume.certifications.first.activity, equals("AWS Certified Solutions Architect"));
    });

    test('hasUsableData returns false for completely empty ResumeData', () {
      const emptyResume = ResumeData();
      expect(emptyResume.hasUsableData, isFalse);
    });

    test('Sanitizes "Not specified" placeholders and recovers candidate name from raw text', () {
      final placeholderJson = {
        "fullName": "Not specified",
        "email": "arunsinghkatal123@gmail.com",
        "phone": "+91 9103506279",
        "location": "Not specified",
        "title": "Not specified",
        "summary": "No professional summary provided."
      };
      const rawText = "ARUN SINGH\n+91 9103506279 | arunsinghkatal123@gmail.com\nSUMMARY\nSoftware Engineer with experience in Flutter.";

      final resume = ResumeData.fromJson(placeholderJson, rawText: rawText);

      expect(resume.fullName, equals("ARUN SINGH"));
      expect(resume.email, equals("arunsinghkatal123@gmail.com"));
      expect(resume.phone, equals("+91 9103506279"));
      expect(resume.location, isEmpty);
      expect(resume.summary, equals("Software Engineer with experience in Flutter."));
    });

    test('Parses candidate resume raw text dynamically into exactly 3 projects, 3 education, 2 experience, and 4 skill groups', () {
      const rawResumeText = '''
NISHANT ARYA
nishaanttx15@gmail.com | +91 9876543210
linkedin.com/in/nishant-arya | github.com/Nishanttxx

SKILLS
Backend Tools: Supabase, Firebase
Testing API: Postman, REST API
Languages: Dart, C++, Python
Soft Skills: Leadership, Communication

EXPERIENCE
AI/ML Intern | 3skill | Remote
Jul 2026 – Present
• Engineered a dynamic AI model pipeline.
• Implemented automated evaluation metrics.

Member | Finite Loop Club-NMAMIT
Aug 2024 – Aug 2025
• Spearheaded technical workshops.
• Organized hackathons and coding events.

PROJECTS
Nexus Search | AI Search Platform | Nishanttxx/Nexus-Searchh
Engineered a dynamic AI search engine utilizing the Gemini API and Flutter.
Developed an interactive querying interface.

AI Voice Digest | AI Content Summarizer | Nishanttxx/Voice-Digest
Architected an AI-powered summarization tool using Flutter.
Implemented intelligent summarization logic.

GST Billing | Invoice Automation Suite | Nishanttxx/Gst_billing
Developed a cross-platform invoicing suite using Flutter and Dart.
Engineered a GSTR-1 reporting system.
Integrated Supabase.

EDUCATION
B.Tech in Information Science & Engineering
NMAM Institute of Technology, Nitte
Aug 2023 – Aug 2027
GPA: 7.84

Class XII (CBSE)
St. Karen's Secondary School, Patna, Bihar
Apr 2023
82%

Class X (CBSE)
St. Karen's School, Patna, Bihar
Apr 2021
88%
''';

      final resume = ResumeData.parseFromRawText(rawResumeText);

      expect(resume.fullName, equals("NISHANT ARYA"));
      expect(resume.email, equals("nishaanttx15@gmail.com"));
      expect(resume.phone, contains("9876543210"));

      // Projects
      expect(resume.projects.length, equals(3));
      expect(resume.projects[0].name, equals("Nexus Search"));
      expect(resume.projects[0].type, equals("AI Search Platform"));
      expect(resume.projects[0].githubUrl, equals("https://github.com/Nishanttxx/Nexus-Searchh"));
      expect(resume.projects[0].effectiveBullets.length, equals(2));

      expect(resume.projects[1].name, equals("AI Voice Digest"));
      expect(resume.projects[1].type, equals("AI Content Summarizer"));
      expect(resume.projects[1].githubUrl, equals("https://github.com/Nishanttxx/Voice-Digest"));
      expect(resume.projects[1].effectiveBullets.length, equals(2));

      expect(resume.projects[2].name, equals("GST Billing"));
      expect(resume.projects[2].type, equals("Invoice Automation Suite"));
      expect(resume.projects[2].githubUrl, equals("https://github.com/Nishanttxx/Gst_billing"));
      expect(resume.projects[2].effectiveBullets.length, equals(3));

      // Education
      expect(resume.education.length, equals(3));
      expect(resume.education[0].degree, contains("B.Tech"));
      expect(resume.education[0].institution, contains("NMAM Institute of Technology"));
      expect(resume.education[0].startDate, contains("Aug 2023"));
      expect(resume.education[0].endDate, contains("Aug 2027"));
      expect(resume.education[0].gpa, contains("7.84"));

      expect(resume.education[1].degree, contains("Class XII"));
      expect(resume.education[1].institution, contains("St. Karen's Secondary School"));
      expect(resume.education[1].startDate, contains("Apr 2023"));
      expect(resume.education[1].gpa, contains("82%"));

      expect(resume.education[2].degree, contains("Class X"));
      expect(resume.education[2].institution, contains("St. Karen's School"));
      expect(resume.education[2].startDate, contains("Apr 2021"));
      expect(resume.education[2].gpa, contains("88%"));

      // Experience
      expect(resume.experience.length, equals(2));
      expect(resume.experience[0].role, equals("AI/ML Intern"));
      expect(resume.experience[0].company, equals("3skill"));
      expect(resume.experience[0].location, equals("Remote"));
      expect(resume.experience[0].startDate, equals("Jul 2026"));
      expect(resume.experience[0].endDate, equals("Present"));
      expect(resume.experience[0].description.length, equals(2));

      expect(resume.experience[1].role, equals("Member"));
      expect(resume.experience[1].company, equals("Finite Loop Club-NMAMIT"));
      expect(resume.experience[1].startDate, equals("Aug 2024"));
      expect(resume.experience[1].endDate, equals("Aug 2025"));
      expect(resume.experience[1].description.length, equals(2));

      // Skills
      expect(resume.skillGroups.length, equals(4));
      expect(resume.skillGroups.map((g) => g.category), containsAll(["Backend Tools", "Testing API", "Languages", "Soft Skills"]));
    });

    test('Parses AI JSON response for candidate resume with 3 projects, 3 education, 2 experience, and 4 skill groups', () {
      final aiJson = {
        "fullName": "NISHANT ARYA",
        "email": "nishaanttx15@gmail.com",
        "phone": "+91 9876543210",
        "linkedin": "https://linkedin.com/in/nishant-arya",
        "github": "https://github.com/Nishanttxx",
        "skillGroups": [
          {"category": "Backend Tools", "items": ["Supabase", "Firebase"]},
          {"category": "Testing API", "items": ["Postman", "REST API"]},
          {"category": "Languages", "items": ["Dart", "C++", "Python"]},
          {"category": "Soft Skills", "items": ["Leadership", "Communication"]}
        ],
        "experience": [
          {
            "company": "3skill",
            "role": "AI/ML Intern",
            "location": "Remote",
            "startDate": "Jul 2026",
            "endDate": "Present",
            "description": [
              "Engineered a dynamic AI model pipeline.",
              "Implemented automated evaluation metrics."
            ]
          },
          {
            "company": "Finite Loop Club-NMAMIT",
            "role": "Member",
            "startDate": "Aug 2024",
            "endDate": "Aug 2025",
            "description": [
              "Spearheaded technical workshops.",
              "Organized hackathons and coding events."
            ]
          }
        ],
        "projects": [
          {
            "name": "Nexus Search",
            "type": "AI Search Platform",
            "githubUrl": "https://github.com/Nishanttxx/Nexus-Searchh",
            "description": [
              "Engineered a dynamic AI search engine utilizing the Gemini API and Flutter.",
              "Developed an interactive querying interface."
            ]
          },
          {
            "name": "AI Voice Digest",
            "type": "AI Content Summarizer",
            "githubUrl": "https://github.com/Nishanttxx/Voice-Digest",
            "description": [
              "Architected an AI-powered summarization tool using Flutter.",
              "Implemented intelligent summarization logic."
            ]
          },
          {
            "name": "GST Billing",
            "type": "Invoice Automation Suite",
            "githubUrl": "https://github.com/Nishanttxx/Gst_billing",
            "description": [
              "Developed a cross-platform invoicing suite using Flutter and Dart.",
              "Engineered a GSTR-1 reporting system.",
              "Integrated Supabase."
            ]
          }
        ],
        "education": [
          {
            "degree": "B.Tech in Information Science & Engineering",
            "institution": "NMAM Institute of Technology, Nitte",
            "startDate": "Aug 2023",
            "endDate": "Aug 2027",
            "gpa": "7.84"
          },
          {
            "degree": "Class XII (CBSE)",
            "institution": "St. Karen's Secondary School, Patna, Bihar",
            "startDate": "Apr 2023",
            "gpa": "82%"
          },
          {
            "degree": "Class X (CBSE)",
            "institution": "St. Karen's School, Patna, Bihar",
            "startDate": "Apr 2021",
            "gpa": "88%"
          }
        ]
      };

      final resume = ResumeData.fromJson(aiJson);

      expect(resume.fullName, equals("NISHANT ARYA"));
      expect(resume.projects.length, equals(3));
      expect(resume.education.length, equals(3));
      expect(resume.experience.length, equals(2));
      expect(resume.skillGroups.length, equals(4));
    });

    test('Parses raw text stream with section headers and records correctly', () {
      const pdfTextStream = '''
NISHANT ARYA
nishaanttx15@gmail.com | +91 9876543210
linkedin.com/in/nishant-arya | github.com/Nishanttxx

SKILLS
Backend Tools: Supabase, Firebase
Testing API: Postman, REST API
Languages: Dart, C++, Python
Soft Skills: Leadership, Communication

EXPERIENCE
AI/ML Intern | 3skill | Remote
Jul 2026 – Present
• Engineered a dynamic AI model pipeline.
• Implemented automated evaluation metrics.
Member | Finite Loop Club-NMAMIT
Aug 2024 – Aug 2025
• Spearheaded technical workshops.
• Organized hackathons.

PROJECTS
Nexus Search | AI Search Platform | Nishanttxx/Nexus-Searchh
Engineered a dynamic AI search engine utilizing the Gemini API and Flutter.
Developed an interactive querying interface.
AI Voice Digest | AI Content Summarizer | Nishanttxx/Voice-Digest
Architected an AI-powered summarization tool using Flutter.
Implemented intelligent summarization logic.
GST Billing | Invoice Automation Suite | Nishanttxx/Gst_billing
Developed a cross-platform invoicing suite using Flutter and Dart.
Engineered a GSTR-1 reporting system.
Integrated Supabase.

EDUCATION
B.Tech in Information Science & Engineering
NMAM Institute of Technology, Nitte
Aug 2023 – Aug 2027
GPA: 7.84
Class XII (CBSE)
St. Karen's Secondary School, Patna, Bihar
Apr 2023
82%
Class X (CBSE)
St. Karen's School, Patna, Bihar
Apr 2021
88%
''';

      final resume = ResumeData.parseFromRawText(pdfTextStream);

      expect(resume.fullName, equals("NISHANT ARYA"));
      expect(resume.email, equals("nishaanttx15@gmail.com"));
      expect(resume.phone, contains("9876543210"));
      expect(resume.location, isNot(contains("Python")));
      expect(resume.projects.length, equals(3));
      expect(resume.education.length, equals(3));
      expect(resume.experience.length, equals(2));
      expect(resume.skillGroups.length, equals(4));
    });

    test('Strict semantic record grouping for candidate PDF structure (Projects=3, NOT 29)', () {
      const verbatimPdfStructure = '''
NISHANT ARYA
nishaanttx15@gmail.com | +91 8102908376
linkedin.com/in/nishant-arya | github.com/Nishanttxx

SKILLS
Backend Tools: Python, Pydantic, Docker, Firebase, Supabase, DBMS
Testing API: Postman, REST API
Languages: Dart, C++, Python
Soft Skills: Leadership, Communication, Problem Solving

EXPERIENCE
AI/ML Intern | 3skill | Remote | Jul 2026 Present
- Engineered a predictive ML model pipeline with dynamic feature extraction.
- Developed an AI-based hiring prediction system with automated evaluation.
Member | Finite Loop Club-NMAMIT | Aug 2024 – Aug 2025
- Collaborated with a technical community to organize workshops.
- Applied software engineering principles to mentor students.

PROJECTS
Nexus Search | AI Search Platform | Nishanttxx/Nexus-Searchh
    - Engineered a dynamic AI search engine utilizing the Gemini API and Flutter,
      implementing advanced Prompt Engineering to optimize the accuracy and reliability
      of LLM responses.
    - Developed an interactive querying interface to handle real-time user interactions,
      focusing on the seamless integration of Generative AI components into a
      high-performance React frontend.

AI Voice Digest | AI Content Summarizer | Nishanttxx/Voice-Digest
    - Architected an AI-powered summarization tool using Flutter, integrating real-time
      transcription and API orchestration for automated content processing and data synchronization.
    - Implemented intelligent summarization logic to transform unstructured voice data
      into concise digests, demonstrating capabilities in AI-driven data optimization
      and NLP pipelines.

GST Billing | Invoice Automation Suite | Nishanttxx/Gst_billing
    - Developed a cross-platform invoicing suite using Flutter and Dart, implementing an
      automated tax engine to calculate CGST, SGST, and IGST in real-time for diverse clients.
    - Engineered a GSTR-1 reporting system that automates the generation of tax-compliant
      CSV/Excel files, reducing manual data entry and increasing filing efficiency for businesses.
    - Integrated Supabase as a Cloud backend for real-time synchronization of business
      profiles and inventory, utilizing Riverpod for reactive state management and global data caching.

EDUCATION
B.Tech in Information Science & Engineering
NMAM Institute of Technology, Nitte
Aug 2023 – Aug 2027
GPA: 7.84

Class XII (CBSE)
St. Karen's Secondary School, Patna, Bihar
Apr 2023
82%

Class X (CBSE)
St. Karen's School, Patna, Bihar
Apr 2021
88%

EXTRACURRICULARS
- Maintained active membership in the Computer Society of India (CSI) contributing to technical discussions.
''';

      final resume = ResumeData.parseFromRawText(verbatimPdfStructure);

      expect(resume.fullName, equals("NISHANT ARYA"));
      expect(resume.email, equals("nishaanttx15@gmail.com"));
      expect(resume.phone, equals("+91 8102908376"));
      expect(resume.location, isNot(contains("Python")));

      // Projects: EXACTLY 3 (NOT 29)
      expect(resume.projects.length, equals(3));
      
      // Project 1
      expect(resume.projects[0].name, equals("Nexus Search"));
      expect(resume.projects[0].type, equals("AI Search Platform"));
      expect(resume.projects[0].githubUrl, contains("Nexus-Searchh"));
      expect(resume.projects[0].descriptionBullets.length, equals(2));
      expect(resume.projects[0].descriptionBullets[0], contains("Gemini API and Flutter"));
      expect(resume.projects[0].descriptionBullets[0], contains("LLM responses."));
      expect(resume.projects[0].descriptionBullets[1], contains("React frontend."));

      // Project 2
      expect(resume.projects[1].name, equals("AI Voice Digest"));
      expect(resume.projects[1].type, equals("AI Content Summarizer"));
      expect(resume.projects[1].githubUrl, contains("Voice-Digest"));
      expect(resume.projects[1].descriptionBullets.length, equals(2));
      expect(resume.projects[1].descriptionBullets[0], contains("API orchestration"));
      expect(resume.projects[1].descriptionBullets[1], contains("NLP pipelines."));

      // Project 3
      expect(resume.projects[2].name, equals("GST Billing"));
      expect(resume.projects[2].type, equals("Invoice Automation Suite"));
      expect(resume.projects[2].githubUrl, contains("Gst_billing"));
      expect(resume.projects[2].descriptionBullets.length, equals(3));
      expect(resume.projects[2].descriptionBullets[0], contains("CGST, SGST, and IGST"));
      expect(resume.projects[2].descriptionBullets[1], contains("GSTR-1 reporting system"));
      expect(resume.projects[2].descriptionBullets[2], contains("Supabase"));

      // Experience: EXACTLY 2
      expect(resume.experience.length, equals(2));
      expect(resume.experience[0].role, equals("AI/ML Intern"));
      expect(resume.experience[0].company, equals("3skill"));
      expect(resume.experience[0].description.length, equals(2));
      expect(resume.experience[1].role, equals("Member"));
      expect(resume.experience[1].company, equals("Finite Loop Club-NMAMIT"));
      expect(resume.experience[1].description.length, equals(2));

      // Education: EXACTLY 3
      expect(resume.education.length, equals(3));
      expect(resume.education[0].degree, contains("B.Tech"));
      expect(resume.education[1].degree, contains("Class XII"));
      expect(resume.education[2].degree, contains("Class X"));

      // Skills: EXACTLY 4 groups
      expect(resume.skillGroups.length, equals(4));
      expect(resume.skillGroups.map((g) => g.category), containsAll(["Backend Tools", "Testing API", "Languages", "Soft Skills"]));

      // Extracurriculars: EXACTLY 1
      expect(resume.extracurriculars.length, equals(1));
    });

    test('Sanitizes and re-groups AI response if AI passed fragmented projects', () {
      final fragmentedAiJson = {
        "fullName": "NISHANT ARYA",
        "email": "nishaanttx15@gmail.com",
        "projects": [
          {"name": "Nexus Search", "type": "AI Search Platform", "url": "https://github.com/Nishanttxx/Nexus-Searchh", "description": ["Engineered a dynamic AI search engine utilizing the Gemini API and Flutter, implementing advanced Prompt Engineering to optimize the accuracy and reliability of LLM responses."]},
          {"name": "Developed an interactive querying interface to handle real-time user interactions, focusing on the seamless integration of Generative AI components into a high-performance React frontend.", "description": []},
          {"name": "Gemini API", "description": []},
          {"name": "Flutter", "description": []},
          {"name": "AI Voice Digest", "type": "AI Content Summarizer", "url": "https://github.com/Nishanttxx/Voice-Digest", "description": ["Architected an AI-powered summarization tool using Flutter."]},
          {"name": "Implemented intelligent summarization logic to transform unstructured voice data into concise digests.", "description": []},
          {"name": "GST Billing", "type": "Invoice Automation Suite", "url": "https://github.com/Nishanttxx/Gst_billing", "description": ["Developed a cross-platform invoicing suite using Flutter and Dart."]},
          {"name": "Engineered a GSTR-1 reporting system.", "description": []},
          {"name": "Integrated Supabase as a Cloud backend.", "description": []}
        ]
      };

      final resume = ResumeData.fromJson(fragmentedAiJson);
      expect(resume.projects.length, equals(3));
      expect(resume.projects[0].name, equals("Nexus Search"));
      expect(resume.projects[1].name, equals("AI Voice Digest"));
      expect(resume.projects[2].name, equals("GST Billing"));
      expect(resume.projects[0].descriptionBullets.length, greaterThanOrEqualTo(2));
      expect(resume.projects[1].descriptionBullets.length, greaterThanOrEqualTo(2));
      expect(resume.projects[2].descriptionBullets.length, greaterThanOrEqualTo(3));
    });
  });
}
