import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/backend_config.dart';
import 'supabase_service.dart';

class BugReportData {
  final String userEmail;
  final String title;
  final String description;
  final String? pageUrl;
  final String? route;
  final String? browser;
  final String? os;
  final String? screenSize;
  final Uint8List? screenshotBytes;
  final String? screenshotFileName;

  BugReportData({
    required this.userEmail,
    required this.title,
    required this.description,
    this.pageUrl,
    this.route,
    this.browser,
    this.os,
    this.screenSize,
    this.screenshotBytes,
    this.screenshotFileName,
  });
}

class BugReportService {
  static final BugReportService instance = BugReportService._internal();

  BugReportService._internal();

  static const int maxScreenshotSizeBytes = 5 * 1024 * 1024; // 5 MB Limit
  static const List<String> allowedExtensions = ['png', 'jpg', 'jpeg', 'webp'];
  static const List<String> forbiddenExtensions = [
    'exe', 'bat', 'sh', 'cmd', 'dll', 'bin', 'msi', 'apk', 'dmg', 'js', 'py', 'vbs', 'ps1'
  ];

  /// Validates screenshot file format and size.
  /// Returns `null` if valid, or a user-friendly error string if invalid.
  String? validateScreenshot({
    required String fileName,
    required int fileSizeBytes,
  }) {
    final lowerName = fileName.toLowerCase().trim();
    final parts = lowerName.split('.');
    final ext = parts.length > 1 ? parts.last : '';

    if (forbiddenExtensions.contains(ext)) {
      return 'Executable and script files are strictly prohibited. Please select an image file.';
    }

    if (!allowedExtensions.contains(ext)) {
      return 'Invalid file format. Please upload a PNG, JPG, JPEG, or WEBP screenshot.';
    }

    if (fileSizeBytes > maxScreenshotSizeBytes) {
      final sizeMb = (fileSizeBytes / (1024 * 1024)).toStringAsFixed(1);
      return 'Screenshot size ($sizeMb MB) exceeds the 5.0 MB limit.';
    }

    return null;
  }

  /// Automatically collects non-sensitive technical environment telemetry.
  Map<String, String> collectTelemetry(BuildContext context, {String? currentRoute}) {
    final mediaQuery = MediaQuery.maybeOf(context);
    final sizeStr = mediaQuery != null
        ? '${mediaQuery.size.width.toInt()}x${mediaQuery.size.height.toInt()}'
        : 'Unknown';

    String osName = defaultTargetPlatform.name.toUpperCase();
    String browserName = kIsWeb ? 'Web Browser' : 'Flutter Native App ($osName)';

    if (kIsWeb) {
      browserName = 'Web Browser (Flutter Web)';
    }

    String pageUrl = kIsWeb ? Uri.base.toString() : (currentRoute ?? 'app://jobwink');
    String routeName = currentRoute ?? ModalRoute.of(context)?.settings.name ?? '/';

    return {
      'page_url': pageUrl,
      'route': routeName,
      'browser': browserName,
      'os': osName,
      'screen_size': sizeStr,
    };
  }

  /// Uploads screenshot bytes to Supabase `bug-screenshots` storage bucket.
  Future<String?> uploadScreenshot({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final client = SupabaseService.instance.client;
    if (client == null) {
      debugPrint('[BugReportService] Supabase client unavailable for screenshot upload.');
      return null;
    }

    try {
      final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : 'png';
      final mimeType = ext == 'png'
          ? 'image/png'
          : (ext == 'webp' ? 'image/webp' : 'image/jpeg');

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storagePath = 'reports/${timestamp}_$fileName';

      await client.storage.from('bug-screenshots').uploadBinary(
            storagePath,
            bytes,
            fileOptions: FileOptions(
              contentType: mimeType,
              upsert: true,
            ),
          );

      final publicUrl = client.storage.from('bug-screenshots').getPublicUrl(storagePath);
      return publicUrl;
    } catch (e) {
      debugPrint('[BugReportService] Screenshot upload failed: $e');
      return null;
    }
  }

  /// Submits the bug report to Supabase DB / Backend.
  Future<Map<String, dynamic>> submitBugReport(BugReportData data) async {
    // 1. Client-Side Input Validation
    final email = data.userEmail.trim().toLowerCase();
    if (email.isEmpty || !email.contains('@')) {
      return {'success': false, 'message': 'Please enter a valid email address.'};
    }

    final title = data.title.trim();
    if (title.isEmpty || title.length < 3) {
      return {'success': false, 'message': 'Bug title must be at least 3 characters.'};
    }

    final description = data.description.trim();
    if (description.isEmpty || description.length < 5) {
      return {'success': false, 'message': 'Bug description must be at least 5 characters.'};
    }

    String? screenshotUrl;
    if (data.screenshotBytes != null && data.screenshotFileName != null) {
      final valErr = validateScreenshot(
        fileName: data.screenshotFileName!,
        fileSizeBytes: data.screenshotBytes!.length,
      );
      if (valErr != null) {
        return {'success': false, 'message': valErr};
      }

      screenshotUrl = await uploadScreenshot(
        bytes: data.screenshotBytes!,
        fileName: data.screenshotFileName!,
      );
    }

    final client = SupabaseService.instance.client;

    // 2. Primary: Submit via Backend HTTP API endpoint to trigger server-side email dispatch
    try {
      final backendUrl = Uri.parse('${BackendConfig.baseUrl}/api/report-bug');
      final currentUser = SupabaseService.instance.currentUser;
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      if (currentUser != null) {
        headers['X-User-ID'] = currentUser.id;
      }

      final body = jsonEncode({
        'user_email': email,
        'title': title,
        'description': description,
        'page_url': data.pageUrl,
        'route': data.route,
        'browser': data.browser,
        'os': data.os,
        'screen_size': data.screenSize,
        'screenshot_reference': screenshotUrl,
      });

      final httpRes = await http.post(backendUrl, headers: headers, body: body);
      if (httpRes.statusCode == 200) {
        final decoded = jsonDecode(httpRes.body);
        return {
          'success': true,
          'report_id': decoded['report_id'],
          'message': decoded['message'] ?? 'Bug reported successfully. Thank you for helping us improve the website!'
        };
      }
    } catch (e) {
      debugPrint('[BugReportService] Backend API note: $e, trying RPC fallback');
    }

    // 3. Fallback: Submit directly via Supabase RPC if backend server is unreachable
    if (client != null) {
      try {
        final response = await client.rpc('submit_bug_report', params: {
          'p_user_email': email,
          'p_title': title,
          'p_description': description,
          'p_user_id': SupabaseService.instance.currentUser?.id,
          'p_page_url': data.pageUrl,
          'p_route': data.route,
          'p_browser': data.browser,
          'p_os': data.os,
          'p_screen_size': data.screenSize,
          'p_screenshot_reference': screenshotUrl,
        });

        if (response != null && response is Map && response['success'] == true) {
          return {
            'success': true,
            'report_id': response['report_id'],
            'message': 'Bug reported successfully. Thank you for helping us improve the website!'
          };
        }
      } catch (e) {
        debugPrint('[BugReportService] Supabase RPC error: $e');
      }
    }

    return {
      'success': false,
      'message': 'Unable to send the bug report. Please ensure backend server is running.'
    };
  }
}
