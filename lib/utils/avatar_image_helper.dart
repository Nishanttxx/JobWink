import 'package:flutter/material.dart';

/// Helper to track failed avatar image URLs across the application session
/// and provide safe rendering with fallback initials.
class AvatarImageHelper {
  static final Set<String> _failedUrls = <String>{};

  /// Returns true if [url] is null, empty, or has failed to load previously.
  static bool isFailed(String? url) {
    if (url == null || url.trim().isEmpty) return true;
    return _failedUrls.contains(url.trim());
  }

  /// Marks [url] as failed so no network retries are attempted.
  static void markFailed(String? url) {
    if (url != null && url.trim().isNotEmpty) {
      _failedUrls.add(url.trim());
    }
  }

  /// Builds a network image with silent error handling and initials fallback.
  static Widget buildAvatarImage({
    required String? avatarUrl,
    required String initials,
    required double width,
    required double height,
    required Widget Function(BuildContext context, String initials) fallbackBuilder,
    BoxFit fit = BoxFit.cover,
  }) {
    final cleanUrl = avatarUrl?.trim();
    if (cleanUrl == null || cleanUrl.isEmpty || _failedUrls.contains(cleanUrl)) {
      return Builder(builder: (context) => fallbackBuilder(context, initials));
    }

    return Image.network(
      cleanUrl,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        markFailed(cleanUrl);
        return fallbackBuilder(context, initials);
      },
    );
  }
}
