import 'dart:typed_data';

import 'web_download_stub.dart'
    if (dart.library.html) 'web_download_web.dart';

/// Triggers a browser file download when running on Flutter Web.
void saveAndDownloadFile(Uint8List bytes, String filename, String mimeType) {
  downloadFileInBrowser(bytes, filename, mimeType);
}
