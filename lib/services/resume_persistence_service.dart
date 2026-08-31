import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/resume_data.dart';
import '../models/resume_history_item.dart';

/// Persists AI-parsed resume data to Supabase (resumes + resume_versions tables).
class ResumePersistenceService {
  static final ResumePersistenceService instance =
      ResumePersistenceService._internal();
  ResumePersistenceService._internal();

  SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  String? get _userId => _client?.auth.currentUser?.id;

  /// Saves parsed resume data to the database.
  ///
  /// Creates or updates a resume row and inserts a new version with the
  /// full parsed content stored as JSONB.
  Future<void> saveParsedResume(ResumeData data) async {
    final client = _client;
    final userId = _userId;
    if (userId == null || client == null) {
      debugPrint('[ResumePersistence] No authenticated user or uninitialized client — skipping save');
      return;
    }

    try {
      // 1. Check for an existing resume for this user
      List<dynamic> existingResumes = [];
      try {
        existingResumes = await client
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
            existingResumes = await client
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
          await client.from('resumes').update({
            'extracted_data': data.toJson(),
            'updated_at': DateTime.now().toIso8601String(),
          }).eq('id', resumeId);
        } catch (e) {
          debugPrint('[ResumePersistence] Note updating resumes.extracted_data: $e');
        }
      } else {
        // Create new resume record
        try {
          final newResume = await client.from('resumes').insert({
            'user_id': userId,
            'extracted_data': data.toJson(),
          }).select('id').single();
          resumeId = newResume['id'] as String;
        } catch (insertErr) {
          debugPrint('[ResumePersistence] Column insert note ($insertErr). Inserting base resume...');
          try {
            final newResume = await client.from('resumes').insert({
              'user_id': userId,
            }).select('id').single();
            resumeId = newResume['id'] as String;
          } on PostgrestException catch (pgErr) {
            if (pgErr.code == '23503' || pgErr.code == '42501') {
              await _ensureProfileRow(userId, data);
              final newResume = await client.from('resumes').insert({
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
        final versions = await client
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
      final versionRow = await client.from('resume_versions').insert({
        'resume_id': resumeId,
        'user_id': userId,
        'version_number': nextVersion,
        'parsed_content': data.toJson(),
        'change_summary': 'AI-parsed from uploaded resume',
      }).select('id').single();

      // 4. Update resume to point to current_version_id
      try {
        await client.from('resumes').update({
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
  Future<ResumeData?> loadLatestParsedResume({String? fileHash}) async {
    final client = _client;
    final userId = _userId;
    if (userId == null || client == null) return null;

    // 1. Try fetching from resume_versions table (parsed_content JSONB)
    try {
      final versions = await client
          .from('resume_versions')
          .select('parsed_content')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1);

      if (versions.isNotEmpty && versions.first['parsed_content'] != null) {
        final content = versions.first['parsed_content'] as Map<String, dynamic>;
        final parsed = ResumeData.validateAndSanitizeAll(ResumeData.fromJson(content));
        final cachedHash = content['fileHash'] as String? ?? content['file_hash'] as String? ?? '';
        final isHashValid = fileHash == null || fileHash.isEmpty || cachedHash.isEmpty || cachedHash == fileHash;

        if (isHashValid && (parsed.hasStructuredSections || parsed.fullName.isNotEmpty || parsed.email.isNotEmpty)) {
          debugPrint('[ResumePersistence] Loaded user resume version from Supabase for user $userId');
          return parsed;
        }
      }
    } catch (vErr) {
      debugPrint('[ResumePersistence] resume_versions load note: $vErr');
    }

    // 2. Try fetching from resumes table (extracted_data JSONB)
    try {
      final resumes = await client
          .from('resumes')
          .select('extracted_data')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1);

      if (resumes.isNotEmpty && resumes.first['extracted_data'] != null) {
        final content = resumes.first['extracted_data'] as Map<String, dynamic>;
        final parsed = ResumeData.validateAndSanitizeAll(ResumeData.fromJson(content));
        final cachedHash = content['fileHash'] as String? ?? content['file_hash'] as String? ?? '';
        final isHashValid = fileHash == null || fileHash.isEmpty || cachedHash.isEmpty || cachedHash == fileHash;

        if (isHashValid && (parsed.hasStructuredSections || parsed.fullName.isNotEmpty || parsed.email.isNotEmpty)) {
          debugPrint('[ResumePersistence] Loaded user extracted_data from resumes table for user $userId');
          return parsed;
        }
      }
    } catch (rErr) {
      debugPrint('[ResumePersistence] resumes extracted_data load note: $rErr');
    }

    return null;
  }

  /// Fetches historical resume versions scoped strictly to the authenticated user.
  ///
  /// Newest resumes appear first (ordered by `created_at` descending).
  /// Enforces database Row-Level Security (RLS) and does NOT consume resume quota.
  Future<List<ResumeHistoryItem>> loadResumeHistory({int limit = 50, int offset = 0}) async {
    final client = _client;
    final userId = _userId;
    if (userId == null || client == null) {
      debugPrint('[ResumePersistence] loadResumeHistory: No authenticated user or uninitialized client');
      return [];
    }

    try {
      // 1. Query resume_versions with parent resumes join scoped to current user
      final versionsResponse = await client
          .from('resume_versions')
          .select('id, resume_id, user_id, version_number, parsed_content, change_summary, created_at, updated_at, resumes(id, title, template_type)')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final List<dynamic> rows = versionsResponse as List<dynamic>;
      final List<ResumeHistoryItem> items = [];

      for (final row in rows) {
        if (row is Map<String, dynamic>) {
          try {
            final item = ResumeHistoryItem.fromMap(row);
            if (item.resumeData.hasUsableData ||
                item.resumeData.fullName.isNotEmpty ||
                item.resumeData.hasStructuredSections) {
              items.add(item);
            }
          } catch (itemErr) {
            debugPrint('[ResumePersistence] Error parsing history item: $itemErr');
          }
        }
      }

      // 2. Fallback: If no resume_versions found, check `resumes` table directly
      if (items.isEmpty) {
        final legacyResumes = await client
            .from('resumes')
            .select('id, user_id, title, template_type, extracted_data, created_at, updated_at')
            .eq('user_id', userId)
            .order('created_at', ascending: false)
            .range(offset, offset + limit - 1);

        for (final row in (legacyResumes as List<dynamic>)) {
          if (row is Map<String, dynamic> && row['extracted_data'] != null) {
            try {
              final item = ResumeHistoryItem.fromMap(row);
              if (item.resumeData.hasUsableData ||
                  item.resumeData.fullName.isNotEmpty ||
                  item.resumeData.hasStructuredSections) {
                items.add(item);
              }
            } catch (_) {}
          }
        }
      }

      debugPrint('[ResumePersistence] Loaded ${items.length} historical resume(s) for user $userId');
      return items;
    } catch (e) {
      debugPrint('[ResumePersistence] loadResumeHistory error: $e');
      return [];
    }
  }

  /// Fetches all resumes owned by the authenticated user.
  Future<List<Map<String, dynamic>>> loadUserResumes() async {
    final client = _client;
    final userId = _userId;
    if (userId == null || client == null) return [];
    try {
      final resumes = await client
          .from('resumes')
          .select('id, user_id, extracted_data, created_at, updated_at')
          .eq('user_id', userId)
          .order('updated_at', ascending: false);
      return List<Map<String, dynamic>>.from(resumes);
    } catch (e) {
      debugPrint('[ResumePersistence] loadUserResumes note: $e');
      return [];
    }
  }

  /// Helper to ensure profile record exists without throwing RLS errors
  Future<void> _ensureProfileRow(String userId, ResumeData data) async {
    final client = _client;
    if (client == null) return;
    final authUser = client.auth.currentUser;
    final userEmail = authUser?.email ?? 'user_${userId.length > 8 ? userId.substring(0, 8) : userId}@jobwink.app';
    final authName = authUser?.userMetadata?['full_name'] as String? ??
        authUser?.userMetadata?['name'] as String?;

    try {
      final existing = await client.from('profiles').select('id').eq('id', userId).maybeSingle();
      if (existing == null) {
        await client.from('profiles').insert({
          'id': userId,
          'email': userEmail,
          'full_name': authName ?? (userEmail.split('@').first),
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
    final client = _client;
    final userId = _userId;
    if (userId == null || client == null) return;

    try {
      await client.from('ats_analysis').insert({
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
          await client.from('ats_analysis').insert({
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
