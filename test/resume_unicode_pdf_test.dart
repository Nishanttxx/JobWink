import 'package:flutter_test/flutter_test.dart';
import 'package:jobwink/models/resume_data.dart';
import 'package:jobwink/services/resume_export_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Unicode-Capable PDF Font Rendering Tests', () {
    test('Unicode characters (₹, €, £, ©, ™, é, ü, ñ, —, –, “, ”, •, →) render cleanly in single-page PDF', () async {
      final unicodeResume = ResumeData(
        fullName: 'François René Müller-₹',
        email: 'francois.rene@muller.eu',
        phone: '+33 6 12 34 56 78',
        location: 'Paris, France — Île-de-France',
        linkedin: 'https://linkedin.com/in/francois-rene',
        github: 'https://github.com/francoisrene',
        title: 'Senior FinTech Architect & Lead Consultant © 2026™',
        summary: 'Expert en ingénierie logicielle avec plus de 8 ans d’expérience. Spécialisé dans les transactions à haute fréquence (budget: ₹50M / €2.5M / £1.8M) et architectures distribuées “Zero-Trust” → performance p99 < 5ms.',
        skills: [
          'Dart', 'Flutter', 'Go', 'Rust', 'Python 3.12™',
          'Systèmes Distribués', 'Microservices', 'Kafka',
          'Sécurité & Chiffrement', 'DevOps & CI/CD'
        ],
        experience: [
          ExperienceEntry(
            company: 'Société Générale FinTech — Global',
            role: 'Lead Architect & Ingénieur Principal',
            location: 'Paris, France',
            startDate: '2021',
            endDate: 'Présent',
            description: [
              'Conception d’un moteur de routage financier gérant plus de 100 000 transactions/seconde avec une disponibilité de 99.99%.',
              'Économies d’infrastructure réalisées: ~€450 000 / an grâce à l’optimisation mémoire en Rust.',
              'Mise en œuvre du protocole de conformité réglementaire bancaire européenne (RGPD / GDPR).',
            ],
          ),
        ],
        projects: [
          ProjectEntry(
            name: 'Projet “Étoile” — Crypto Gateway',
            type: 'Passerelle de Paiement',
            descriptionBullets: [
              'Passerelle multi-devises supportant l’Euro (€), la Livre (£), et la Roupie (₹).',
              'Intégration d’algorithmes de détection de fraude en temps réel → latence < 10ms.',
            ],
            technologies: ['Flutter', 'Go', 'Redis', 'PostgreSQL'],
          ),
        ],
        education: [
          EducationEntry(
            institution: 'École Polytechnique',
            degree: 'Diplôme d’Ingénieur / M.S.',
            fieldOfStudy: 'Informatique & Mathématiques Appliquées',
            startDate: '2016',
            endDate: '2019',
            gpa: 'Mention Très Bien',
          ),
        ],
        extracurriculars: [
          ExtracurricularEntry(
            activity: 'Conférencier — Forum Européen de l’Architecture Cloud',
            organization: 'Paris Tech Summit',
            description: 'Présentation sur la résilience des microservices face aux pannes réseau.',
          ),
        ],
      );

      final pdfBytes = await ResumeExportService.instance.generateAtsPdf(unicodeResume);
      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(2000));

      final config = ResumeExportService.instance.optimizeResumeConfig(
        unicodeResume,
        const PdfTemplateConfig(),
      );
      final measurement = ResumeExportService.instance.measureResumeLayout(unicodeResume, config);

      expect(measurement.pageCount, equals(1));
      expect(measurement.overflow, isFalse);
    });
  });
}
