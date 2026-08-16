import 'package:flutter_test/flutter_test.dart';
import 'package:jobwink/models/resume_data.dart';

void main() {
  group('ProjectEntry parsing and description extraction', () {
    test('combines string description and bullet highlights correctly', () {
      final json = {
        'name': 'JobWink Resume Studio',
        'description': 'AI-powered resume parsing platform',
        'highlights': [
          'Implemented multi-provider LLM fallback pipeline',
          'Engineered ATS optimization algorithm'
        ],
        'technologies': ['Flutter', 'Gemini AI', 'Supabase'],
        'url': 'https://github.com/example/jobwink'
      };

      final project = ProjectEntry.fromJson(json);

      expect(project.name, equals('JobWink Resume Studio'));
      expect(project.url, equals('https://github.com/example/jobwink'));
      expect(project.technologies, containsAll(['Flutter', 'Gemini AI', 'Supabase']));

      // Assert that all bullet points are present in description
      expect(project.description, contains('Implemented multi-provider LLM fallback pipeline'));
      expect(project.description, contains('Engineered ATS optimization algorithm'));
    });

    test('extracts multiline bullet points when description is a List', () {
      final json = {
        'projectName': 'Nexus Search Engine',
        'bullets': [
          'Built semantic search index using Vector Embeddings',
          'Optimized search response latency to <50ms'
        ],
        'tools': ['Dart', 'Python', 'Redis']
      };

      final project = ProjectEntry.fromJson(json);

      expect(project.name, equals('Nexus Search Engine'));
      expect(project.description, contains('Built semantic search index using Vector Embeddings'));
      expect(project.description, contains('Optimized search response latency to <50ms'));
    });

    test('returns empty string when description fields are missing', () {
      final json = {
        'name': 'Standalone Tool',
        'url': 'https://github.com/example/tool'
      };

      final project = ProjectEntry.fromJson(json);

      expect(project.name, equals('Standalone Tool'));
      expect(project.description, isEmpty);
    });
  });
}
