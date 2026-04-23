import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:printing/printing.dart';

class NativeDownloadService {
  static Future<void> downloadPdf(Uint8List bytes, String fileName) async {
    if (kIsWeb) return;

    try {
      if (Platform.isAndroid) {
        // Sur Android, on essaie de sauvegarder dans le dossier Downloads public
        final directory = Directory('/storage/emulated/0/Download');
        if (await directory.exists()) {
          final file = File('${directory.path}/$fileName');
          await file.writeAsBytes(bytes);
          debugPrint("Fichier sauvegardé dans Downloads: ${file.path}");
          return;
        }
      }

      // Pour iOS ou si le dossier Android Downloads n'est pas accessible
      // On utilise le comportement standard de partage qui permet de "Sauvegarder dans Fichiers"
      await Printing.sharePdf(bytes: bytes, filename: fileName);
      
    } catch (e) {
      debugPrint("Erreur de téléchargement natif: $e");
      // En cas d'erreur, on bascule sur le partage standard
      await Printing.sharePdf(bytes: bytes, filename: fileName);
    }
  }
}
