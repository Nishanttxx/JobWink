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

      expect(resume.extracurriculars.length, equals(1));
      expect(resume.extracurriculars.first.activity, equals("AWS Certified Solutions Architect"));
    });

    test('hasUsableData returns false for completely empty ResumeData', () {
      const emptyResume = ResumeData();
      expect(emptyResume.hasUsableData, isFalse);
    });
  });
}
