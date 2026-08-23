import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/resume_data.dart';

/// Persists AI-parsed resume data to Supabase (resumes + resume_versions tables).
class ResumePersistenceService {
  static final ResumePersistenceService instance =
      ResumePersistenceService._internal();
  ResumePersistenceService._internal();

  SupabaseClient get _client => Supabase.instance.client;
  String? get _userId => _client.auth.currentUser?.id;

  /// Saves parsed resume data to the database.
  ///
  /// Creates or updates a resume row and inserts a new version with the
  /// full parsed content stored as JSONB.
  Future<void> saveParsedResume(ResumeData data) async {
    final userId = _userId;
    if (userId == null) {
      debugPrint('[ResumePersistence] No authenticated user — skipping save');
      return;
    }

    try {
      // 1. Check for an existing resume for this user
      List<dynamic> existingResumes = [];
      try {
        existingResumes = await _client
            .from('resumes')
            .select('id')
            .eq('user_id', userId)
            .order('created_at', ascending: false)
            .limit(1);
      } catch (e) {
        // If query fails (e.g. user profile not ready or RLS restricted), attempt profile creation fallback
        if (e.toString().contains('42501') || e.toString().contains('23503')) {
          await _ensureProfileRow(userId, data);
          try {
            existingResumes = await _client
                .from('resumes')
                .select('id')
                .eq('user_id', userId)
                .order('created_at', ascending: false)
                .limit(1);
          } catch (_) {}
        }
      }

      String resumeId;

      if (existingResumes.isNotEmpty) {
        resumeId = existingResumes.first['id'] as String;
        try {
          await _client.from('resumes').update({
            'extracted_data': data.toJson(),
            'updated_at': DateTime.now().toIso8601String(),
          }).eq('id', resumeId);
        } catch (e) {
          debugPrint('[ResumePersistence] Note updating resumes.extracted_data: $e');
        }
      } else {
        // Create new resume record
        try {
          final newResume = await _client.from('resumes').insert({
            'user_id': userId,
            'extracted_data': data.toJson(),
          }).select('id').single();
          resumeId = newResume['id'] as String;
        } catch (insertErr) {
          debugPrint('[ResumePersistence] Column insert note ($insertErr). Inserting base resume...');
          try {
            final newResume = await _client.from('resumes').insert({
              'user_id': userId,
            }).select('id').single();
            resumeId = newResume['id'] as String;
          } on PostgrestException catch (pgErr) {
            if (pgErr.code == '23503' || pgErr.code == '42501') {
              await _ensureProfileRow(userId, data);
              final newResume = await _client.from('resumes').insert({
                'user_id': userId,
              }).select('id').single();
              resumeId = newResume['id'] as String;
            } else {
              rethrow;
            }
          }
        }
      }

      // 2. Determine next version number from resume_versions
      int nextVersion = 1;
      try {
        final versions = await _client
            .from('resume_versions')
            .select('version_number')
            .eq('resume_id', resumeId)
            .order('version_number', ascending: false)
            .limit(1);

        if (versions.isNotEmpty) {
          nextVersion = ((versions.first['version_number'] as num).toInt() + 1);
        }
      } catch (vErr) {
        debugPrint('[ResumePersistence] Version check note: $vErr');
      }

      // 3. Insert new version with full parsed content into resume_versions (parsed_content JSONB)
      final versionRow = await _client.from('resume_versions').insert({
        'resume_id': resumeId,
        'user_id': userId,
        'version_number': nextVersion,
        'parsed_content': data.toJson(),
        'change_summary': 'AI-parsed from uploaded resume',
      }).select('id').single();

      // 4. Update resume to point to current_version_id
      try {
        await _client.from('resumes').update({
          'current_version_id': versionRow['id'],
        }).eq('id', resumeId);
      } catch (_) {}

      debugPrint(
          '[ResumePersistence] Saved resume version $nextVersion for resume $resumeId');
    } catch (e) {
      debugPrint('[ResumePersistence] Note: Persistence skipped ($e)');
    }
  }

  /// Loads the latest saved resume data for the authenticated user from Supabase.
  ///
  /// Cache is valid ONLY when parserVersion matches [ResumeData.currentParserVersion]
  /// and (if [fileHash] is specified) matches the expected PDF hash.
  Future<ResumeData?> loadLatestParsedResume({String? fileHash}) async {
    final userId = _userId;
    if (userId == null) return null;

    // 1. Try fetching from resume_versions table (parsed_content JSONB)
    try {
      final versions = await _client
          .from('resume_versions')
          .select('parsed_content')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1);

      if (versions.isNotEmpty && versions.first['parsed_content'] != null) {
        final content = versions.first['parsed_content'] as Map<String, dynamic>;
        final parsed = ResumeData.fromJson(content);
        final version = content['parserVersion'] as String? ?? content['parser_version'] as String? ?? '';
        final cachedHash = content['fileHash'] as String? ?? content['file_hash'] as String? ?? '';

        final isVersionValid = version == ResumeData.currentParserVersion;
        final isHashValid = fileHash == null || fileHash.isEmpty || cachedHash.isEmpty || cachedHash == fileHash;

        if (isVersionValid && isHashValid && parsed.hasStructuredSections) {
          debugPrint('[ResumePersistence] Loaded cached resume version from Supabase (0 AI calls)');
          return parsed;
        } else {
          debugPrint('[ResumePersistence] Cached version stale or invalid (version="$version" vs "${ResumeData.currentParserVersion}", hashMatch=$isHashValid, hasStructured=${parsed.hasStructuredSections}) — skipping cache');
        }
      }
    } catch (vErr) {
      debugPrint('[ResumePersistence] resume_versions load note: $vErr');
    }

    // 2. Try fetching from resumes table (extracted_data JSONB)
    try {
      final resumes = await _client
          .from('resumes')
          .select('extracted_data')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1);

      if (resumes.isNotEmpty && resumes.first['extracted_data'] != null) {
        final content = resumes.first['extracted_data'] as Map<String, dynamic>;
        final parsed = ResumeData.fromJson(content);
        final version = content['parserVersion'] as String? ?? content['parser_version'] as String? ?? '';
        final cachedHash = content['fileHash'] as String? ?? content['file_hash'] as String? ?? '';

        final isVersionValid = version == ResumeData.currentParserVersion;
        final isHashValid = fileHash == null || fileHash.isEmpty || cachedHash.isEmpty || cachedHash == fileHash;

        if (isVersionValid && isHashValid && parsed.hasStructuredSections) {
          debugPrint('[ResumePersistence] Loaded extracted_data from resumes table (0 AI calls)');
          return parsed;
        } else {
          debugPrint('[ResumePersistence] Cached extracted_data stale or invalid (version="$version" vs "${ResumeData.currentParserVersion}", hashMatch=$isHashValid, hasStructured=${parsed.hasStructuredSections}) — skipping cache');
        }
      }
    } catch (rErr) {
      debugPrint('[ResumePersistence] resumes extracted_data load note: $rErr');
    }

    return null;
  }

  /// Helper to ensure profile record exists without throwing RLS errors
  Future<void> _ensureProfileRow(String userId, ResumeData data) async {
    final userEmail = _client.auth.currentUser?.email ??
        (data.email.trim().isNotEmpty ? data.email.trim() : 'user_${userId.substring(0, 8)}@jobwink.app');

    try {
      final existing = await _client.from('profiles').select('id').eq('id', userId).maybeSingle();
      if (existing == null) {
        await _client.from('profiles').insert({
          'id': userId,
          'email': userEmail,
          'full_name': data.fullName.isNotEmpty ? data.fullName : 'JobWink Candidate',
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('[ResumePersistence] Profile check note: $e');
    }
  }

  /// Saves an ATS analysis result to the database.
  Future<void> saveAtsAnalysis({
    required int overallScore,
    required int formatScore,
    required int contentScore,
    required int keywordScore,
    required Map<String, dynamic> feedback,
  }) async {
    final userId = _userId;
    if (userId == null) return;

    try {
      await _client.from('ats_analysis').insert({
        'user_id': userId,
        'ats_score': overallScore,
        'formatting_score': formatScore,
        'content_score': contentScore,
        'relevance_score': keywordScore,
        'feedback': feedback,
      });
    } catch (e) {
      if (e is PostgrestException && (e.code == '23503' || e.code == '42501')) {
        await _ensureProfileRow(userId, ResumeData());
        try {
          await _client.from('ats_analysis').insert({
            'user_id': userId,
            'ats_score': overallScore,
            'formatting_score': formatScore,
            'content_score': contentScore,
            'relevance_score': keywordScore,
            'feedback': feedback,
          });
        } catch (retryErr) {
          debugPrint('[ResumePersistence] Retry saving ATS analysis note: $retryErr');
        }
      } else {
        debugPrint('[ResumePersistence] Error saving ATS analysis: $e');
      }
    }
  }
}
