import 'package:flutter_test/flutter_test.dart';
import 'package:jobwink/models/resume_data.dart';
import 'package:jobwink/models/resume_type.dart';

void main() {
  ExperienceEntry validExp(String role, String company) => ExperienceEntry(
        role: role,
        company: company,
        description: ['Built scalable systems.'],
      );

  ProjectEntry validProj(String name) => ProjectEntry(
        name: name,
        description: 'Developed full stack app.',
        technologies: ['Flutter', 'Dart'],
      );

  group('Resume Focus Criteria Validation Test Matrix', () {
    test('EXPERIENCE BASED: requires >=3 experiences AND >=2 projects', () {
      final resume3Exp2Proj = ResumeData(
        experience: [validExp('SWE 1', 'Co A'), validExp('SWE 2', 'Co B'), validExp('SWE 3', 'Co C')],
        projects: [validProj('App 1'), validProj('App 2')],
      );
      final resValid = ResumeType.experience.validateCriteria(resume3Exp2Proj);
      expect(resValid.isValid, isTrue);

      final resume2Exp2Proj = ResumeData(
        experience: [validExp('SWE 1', 'Co A'), validExp('SWE 2', 'Co B')],
        projects: [validProj('App 1'), validProj('App 2')],
      );
      final resInvalidExp = ResumeType.experience.validateCriteria(resume2Exp2Proj);
      expect(resInvalidExp.isValid, isFalse);
      expect(resInvalidExp.primaryMessage, 'Meet the criteria to build your resume.');
      expect(resInvalidExp.detailMessage, contains('1 more experience'));

      final resume3Exp1Proj = ResumeData(
        experience: [validExp('SWE 1', 'Co A'), validExp('SWE 2', 'Co B'), validExp('SWE 3', 'Co C')],
        projects: [validProj('App 1')],
      );
      final resInvalidProj = ResumeType.experience.validateCriteria(resume3Exp1Proj);
      expect(resInvalidProj.isValid, isFalse);
      expect(resInvalidProj.detailMessage, contains('1 more project'));
    });

    test('PROJECT BASED: requires >=3 projects AND >=1 experience', () {
      final resume1Exp3Proj = ResumeData(
        experience: [validExp('Intern', 'Co A')],
        projects: [validProj('App 1'), validProj('App 2'), validProj('App 3')],
      );
      final resValid = ResumeType.project.validateCriteria(resume1Exp3Proj);
      expect(resValid.isValid, isTrue);

      final resume1Exp2Proj = ResumeData(
        experience: [validExp('Intern', 'Co A')],
        projects: [validProj('App 1'), validProj('App 2')],
      );
      final resInvalidProj = ResumeType.project.validateCriteria(resume1Exp2Proj);
      expect(resInvalidProj.isValid, isFalse);

      final resume0Exp3Proj = ResumeData(
        experience: const [],
        projects: [validProj('App 1'), validProj('App 2'), validProj('App 3')],
      );
      final resInvalidExp = ResumeType.project.validateCriteria(resume0Exp3Proj);
      expect(resInvalidExp.isValid, isFalse);
    });

    test('HYBRID: requires >=2 experiences AND >=2 projects', () {
      final resume2Exp2Proj = ResumeData(
        experience: [validExp('SWE 1', 'Co A'), validExp('SWE 2', 'Co B')],
        projects: [validProj('App 1'), validProj('App 2')],
      );
      final resValid = ResumeType.hybrid.validateCriteria(resume2Exp2Proj);
      expect(resValid.isValid, isTrue);

      final resume2Exp1Proj = ResumeData(
        experience: [validExp('SWE 1', 'Co A'), validExp('SWE 2', 'Co B')],
        projects: [validProj('App 1')],
      );
      final resInvalidProj = ResumeType.hybrid.validateCriteria(resume2Exp1Proj);
      expect(resInvalidProj.isValid, isFalse);

      final resume1Exp2Proj = ResumeData(
        experience: [validExp('SWE 1', 'Co A')],
        projects: [validProj('App 1'), validProj('App 2')],
      );
      final resInvalidExp = ResumeType.hybrid.validateCriteria(resume1Exp2Proj);
      expect(resInvalidExp.isValid, isFalse);
    });

    test('FRESHER: ALWAYS VALID with no minimum bounds', () {
      final res0Exp0Proj = ResumeType.fresher.validateCriteria(const ResumeData());
      expect(res0Exp0Proj.isValid, isTrue);

      final res0Exp1Proj = ResumeType.fresher.validateCriteria(ResumeData(
        projects: [validProj('App 1')],
      ));
      expect(res0Exp1Proj.isValid, isTrue);

      final res1Exp0Proj = ResumeType.fresher.validateCriteria(ResumeData(
        experience: [validExp('Intern', 'Co A')],
      ));
      expect(res1Exp0Proj.isValid, isTrue);

      final res10Exp10Proj = ResumeType.fresher.validateCriteria(ResumeData(
        experience: List.generate(10, (i) => validExp('Role $i', 'Co $i')),
        projects: List.generate(10, (i) => validProj('Proj $i')),
      ));
      expect(res10Exp10Proj.isValid, isTrue);
    });

    test('EMPTY & PLACEHOLDER RECORDS: are excluded from valid counts', () {
      final resumeWithPlaceholders = ResumeData(
        experience: [
          validExp('Software Engineer', 'Google'),
          const ExperienceEntry(company: '', role: '', description: []),
          const ExperienceEntry(company: 'N/A', role: 'None', description: ['[not specified]']),
          validExp('Backend Lead', 'Amazon'),
          const ExperienceEntry(role: 'Not specified'),
          validExp('DevOps Engineer', 'Meta'),
        ],
        projects: [
          validProj('JobWink Flutter App'),
          ProjectEntry(name: '', description: '', technologies: const []),
          ProjectEntry(name: 'N/A', description: '[not provided]', technologies: const ['None']),
          validProj('AI Resume Parser'),
        ],
      );

      final resExp = ResumeType.experience.validateCriteria(resumeWithPlaceholders);
      expect(resExp.experienceCount, 3);
      expect(resExp.projectCount, 2);
      expect(resExp.isValid, isTrue);
    });

    test('NO MAXIMUM BOUNDS: exceeds minimum requirements gracefully', () {
      final largeResume = ResumeData(
        experience: List.generate(5, (i) => validExp('Role $i', 'Co $i')),
        projects: List.generate(5, (i) => validProj('Proj $i')),
      );

      expect(ResumeType.experience.validateCriteria(largeResume).isValid, isTrue);
      expect(ResumeType.project.validateCriteria(largeResume).isValid, isTrue);
      expect(ResumeType.hybrid.validateCriteria(largeResume).isValid, isTrue);
      expect(ResumeType.fresher.validateCriteria(largeResume).isValid, isTrue);
    });
  });
}
