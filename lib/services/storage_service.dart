import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'demo_service.dart';

/// Exception thrown when a write or mutate operation is attempted in Demo Mode.
class DemoModeException implements Exception {
  final String message;
  const DemoModeException([this.message = 'Action blocked in Demo Mode. Create an account to save data.']);

  @override
  String toString() => 'DemoModeException: $message';
}

/// Enum representing the supported Supabase Storage buckets in JobWink.
enum StorageBucket {
  resumes('resumes'),
  optimizedResumes('optimized-resumes'),
  referenceResumes('reference-resumes'),
  coverLetters('cover-letters');

  final String id;
  const StorageBucket(this.id);
}

/// Service providing low-level operations for Supabase Storage.
class StorageService {
  static final StorageService instance = StorageService._internal();

  StorageService._internal();

  SupabaseClient get _client {
    final client = Supabase.instance.client;
    return client;
  }

  /// Uploads binary bytes to a specific bucket and path.
  Future<String> uploadBinary({
    required StorageBucket bucket,
    required String path,
    required Uint8List bytes,
    String? contentType,
    bool upsert = true,
  }) async {
    if (DemoService.instance.isDemoMode && _client.auth.currentUser == null) {
      throw const DemoModeException('Uploads are blocked in Demo Mode. Sign up for a free account to save files.');
    }

    final storageBucket = _client.storage.from(bucket.id);
    final responsePath = await storageBucket.uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(
        contentType: contentType,
        upsert: upsert,
      ),
    );
    return responsePath;
  }

  /// Downloads binary bytes from a specific bucket and path.
  Future<Uint8List> downloadBinary({
    required StorageBucket bucket,
    required String path,
  }) async {
    final storageBucket = _client.storage.from(bucket.id);
    final bytes = await storageBucket.download(path);
    return bytes;
  }

  /// Deletes a single file from a bucket.
  Future<void> deleteFile({
    required StorageBucket bucket,
    required String path,
  }) async {
    if (DemoService.instance.isDemoMode && _client.auth.currentUser == null) {
      throw const DemoModeException('Deletions are blocked in Demo Mode.');
    }
    final storageBucket = _client.storage.from(bucket.id);
    await storageBucket.remove([path]);
  }

  /// Deletes multiple files from a bucket.
  Future<void> deleteFiles({
    required StorageBucket bucket,
    required List<String> paths,
  }) async {
    if (DemoService.instance.isDemoMode && _client.auth.currentUser == null) {
      throw const DemoModeException('Deletions are blocked in Demo Mode.');
    }
    if (paths.isEmpty) return;
    final storageBucket = _client.storage.from(bucket.id);
    await storageBucket.remove(paths);
  }

  /// Lists all files in a folder path within a bucket.
  Future<List<FileObject>> listFiles({
    required StorageBucket bucket,
    String? path,
  }) async {
    final storageBucket = _client.storage.from(bucket.id);
    return await storageBucket.list(path: path);
  }

  /// Creates a temporary signed URL for downloading private files.
  Future<String> createSignedUrl({
    required StorageBucket bucket,
    required String path,
    int expiresInSeconds = 3600,
  }) async {
    final storageBucket = _client.storage.from(bucket.id);
    return await storageBucket.createSignedUrl(path, expiresInSeconds);
  }

  /// Obtains the public URL for a file in a public bucket (if applicable).
  String getPublicUrl({
    required StorageBucket bucket,
    required String path,
  }) {
    final storageBucket = _client.storage.from(bucket.id);
    return storageBucket.getPublicUrl(path);
  }
}
