import 'dart:typed_data';

/// Fallback no-op implementation for non-web platforms.
void downloadFileInBrowser(Uint8List bytes, String filename, String mimeType) {
  // Non-web platforms do not support browser DOM downloads directly.
}
