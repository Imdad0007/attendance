import 'package:flutter/foundation.dart' show kIsWeb;

// Importation conditionnelle pour éviter les erreurs de compilation sur Mobile
import 'dart:html' as html if (dart.library.io) 'dart:io';

class WebDownloadService {
  static void downloadBytes(List<int> bytes, String fileName) {
    if (kIsWeb) {
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement()
        ..href = url
        ..style.display = 'none'
        ..download = fileName;
      html.document.body?.children.add(anchor);
      anchor.click();
      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url);
    }
  }
}
