import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/storage_service.dart';
import 'storage_result.dart';

/// Domain repository managing user files in Supabase Storage buckets.
///
/// Enforces security & policy boundaries:
/// - Users can only upload, download, and delete files under their own `{userId}/` directory.
/// - `StorageBucket.referenceResumes` is private/backend-only and blocked from direct client access.
class StorageRepository {
  final StorageService _service;

  StorageRepository({StorageService? service})
      : _service = service ?? StorageService.instance;

  String? get _currentUserId => Supabase.instance.client.auth.currentUser?.id;

  /// Helper to enforce user folder scoping.
  String _buildUserPath(String userId, String fileName) {
    // Sanitize fileName to prevent directory traversal
    final cleanFileName = fileName.split('/').last.split('\\').last;
    return '$userId/$cleanFileName';
  }

  /// Validates bucket access rules.
  void _checkBucketAccess(StorageBucket bucket) {
    if (bucket == StorageBucket.referenceResumes) {
      throw StorageException(
        'Access denied: reference-resumes bucket is restricted to backend processing.',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Upload Operations
  // ---------------------------------------------------------------------------

  /// Uploads a resume file for the authenticated user to the `resumes` bucket.
  Future<StorageResult<String>> uploadResume({
    required String fileName,
    required Uint8List bytes,
    String? contentType,
  }) async {
    return uploadFile(
      bucket: StorageBucket.resumes,
      fileName: fileName,
      bytes: bytes,
      contentType: contentType,
    );
  }

  /// Generic upload method enforcing user-folder isolation.
  Future<StorageResult<String>> uploadFile({
    required StorageBucket bucket,
    required String fileName,
    required Uint8List bytes,
    String? contentType,
  }) async {
    try {
      _checkBucketAccess(bucket);
      final userId = _currentUserId;
      if (userId == null) {
        return const StorageFailure('User must be authenticated to upload files.');
      }

      final fullPath = _buildUserPath(userId, fileName);
      final uploadedPath = await _service.uploadBinary(
        bucket: bucket,
        path: fullPath,
        bytes: bytes,
        contentType: contentType,
        upsert: true,
      );

      return StorageSuccess(uploadedPath);
    } on StorageException catch (e) {
      return StorageFailure(e.message);
    } catch (e) {
      return StorageFailure('Failed to upload file: ${e.toString()}');
    }
  }

  // ---------------------------------------------------------------------------
  // Download Operations
  // ---------------------------------------------------------------------------

  /// Downloads a user's resume file from the `resumes` bucket.
  Future<StorageResult<Uint8List>> downloadResume(String fileName) async {
    return downloadFile(bucket: StorageBucket.resumes, fileName: fileName);
  }

  /// Generic download method enforcing user-folder isolation.
  Future<StorageResult<Uint8List>> downloadFile({
    required StorageBucket bucket,
    required String fileName,
  }) async {
    try {
      _checkBucketAccess(bucket);
      final userId = _currentUserId;
      if (userId == null) {
        return const StorageFailure('User must be authenticated to download files.');
      }

      final fullPath = fileName.startsWith('$userId/')
          ? fileName
          : _buildUserPath(userId, fileName);

      final bytes = await _service.downloadBinary(
        bucket: bucket,
        path: fullPath,
      );

      return StorageSuccess(bytes);
    } on StorageException catch (e) {
      return StorageFailure(e.message);
    } catch (e) {
      return StorageFailure('Failed to download file: ${e.toString()}');
    }
  }

  /// Generates a signed download URL for private files.
  Future<StorageResult<String>> getSignedUrl({
    required StorageBucket bucket,
    required String fileName,
    int expiresInSeconds = 3600,
  }) async {
    try {
      _checkBucketAccess(bucket);
      final userId = _currentUserId;
      if (userId == null) {
        return const StorageFailure('User must be authenticated.');
      }

      final fullPath = fileName.startsWith('$userId/')
          ? fileName
          : _buildUserPath(userId, fileName);

      final url = await _service.createSignedUrl(
        bucket: bucket,
        path: fullPath,
        expiresInSeconds: expiresInSeconds,
      );

      return StorageSuccess(url);
    } on StorageException catch (e) {
      return StorageFailure(e.message);
    } catch (e) {
      return StorageFailure('Failed to generate download URL: ${e.toString()}');
    }
  }

  // ---------------------------------------------------------------------------
  // Delete Operations
  // ---------------------------------------------------------------------------

  /// Deletes a user's resume file from the `resumes` bucket.
  Future<StorageResult<void>> deleteResume(String fileName) async {
    return deleteFile(bucket: StorageBucket.resumes, fileName: fileName);
  }

  /// Generic delete method enforcing user-folder isolation.
  Future<StorageResult<void>> deleteFile({
    required StorageBucket bucket,
    required String fileName,
  }) async {
    try {
      _checkBucketAccess(bucket);
      final userId = _currentUserId;
      if (userId == null) {
        return const StorageFailure('User must be authenticated to delete files.');
      }

      final fullPath = fileName.startsWith('$userId/')
          ? fileName
          : _buildUserPath(userId, fileName);

      await _service.deleteFile(
        bucket: bucket,
        path: fullPath,
      );

      return const StorageSuccess(null);
    } on StorageException catch (e) {
      return StorageFailure(e.message);
    } catch (e) {
      return StorageFailure('Failed to delete file: ${e.toString()}');
    }
  }

  // ---------------------------------------------------------------------------
  // List Operations
  // ---------------------------------------------------------------------------

  /// Lists all files in the current user's folder within a bucket.
  Future<StorageResult<List<FileObject>>> listUserFiles({
    required StorageBucket bucket,
  }) async {
    try {
      _checkBucketAccess(bucket);
      final userId = _currentUserId;
      if (userId == null) {
        return const StorageFailure('User must be authenticated.');
      }

      final files = await _service.listFiles(
        bucket: bucket,
        path: userId,
      );

      return StorageSuccess(files);
    } on StorageException catch (e) {
      return StorageFailure(e.message);
    } catch (e) {
      return StorageFailure('Failed to list files: ${e.toString()}');
    }
  }
}
