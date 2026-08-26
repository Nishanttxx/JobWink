import 'package:flutter/material.dart';

/// Helper to provide safe avatar image rendering with fallback initials.
class AvatarImageHelper {
  static final Set<String> _failedUrls = <String>{};

  /// Returns true if [url] is null, empty, or has failed to load previously.
  static bool isFailed(String? url) {
    if (url == null || url.trim().isEmpty) return true;
    return _failedUrls.contains(url.trim());
  }

  /// Marks [url] as failed so no network retries are attempted for that URL.
  static void markFailed(String? url) {
    if (url != null && url.trim().isNotEmpty) {
      _failedUrls.add(url.trim());
    }
  }

  /// Clears a URL from the failed list.
  static void clearFailed(String? url) {
    if (url != null && url.trim().isNotEmpty) {
      _failedUrls.remove(url.trim());
    }
  }

  /// Clears all failed URLs.
  static void clearAll() {
    _failedUrls.clear();
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
    if (cleanUrl == null || cleanUrl.isEmpty) {
      return Builder(builder: (context) => fallbackBuilder(context, initials));
    }

    return Image.network(
      cleanUrl,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return fallbackBuilder(context, initials);
      },
    );
  }
}
