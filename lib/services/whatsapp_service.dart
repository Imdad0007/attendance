import 'dart:convert';
import 'package:attendance/config/app_config.dart';
import 'package:http/http.dart' as http;

class WhatsAppService {
  /// Envoie la notification via Meta ET Green-API en PARALLÈLE
  static Future<bool> sendAbsenceTemplate({
    required String phone,
    required String studentName,
    required String dateAbsence,
    required String courseName,
    required String coursehour,
  }) async {
    // On lance les deux en même temps
    final results = await Future.wait([
      sendGreenApiNotification(
        phone: phone,
        studentName: studentName,
        dateAbsence: dateAbsence,
        courseName: courseName,
        coursehour: coursehour,
      ),
      sendMetaApiNotification(
        phone: phone,
        studentName: studentName,
        dateAbsence: dateAbsence,
        courseName: courseName,
        coursehour: coursehour,
      ),
    ]);

    // Succès si l'un des deux a fonctionné
    return results[0] || results[1];
  }

  /// Méthode isolée pour Meta API
  static Future<bool> sendMetaApiNotification({
    required String phone,
    required String studentName,
    required String dateAbsence,
    required String courseName,
    required String coursehour,
  }) async {
    if (AppConfig.whatsappPhoneNumberId.isEmpty ||
        AppConfig.whatsappToken.isEmpty) {
      return false;
    }

    final url = Uri.parse(
      "https://graph.facebook.com/v19.0/${AppConfig.whatsappPhoneNumberId}/messages",
    );
    final formattedPhone = phone.replaceAll('+', '').replaceAll(' ', '').trim();

    try {
      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer ${AppConfig.whatsappToken}",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "messaging_product": "whatsapp",
          "to": formattedPhone,
          "type": "template",
          "template": {
            "name": "absence_notification",
            "language": {"code": "fr_BE"},
            "components": [
              {
                "type": "body",
                "parameters": [
                  {"type": "text", "text": studentName},
                  {"type": "text", "text": courseName},
                  {"type": "text", "text": dateAbsence},
                  {"type": "text", "text": coursehour},
                ],
              },
            ],
          },
        }),
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        print("Erreur Meta API (${response.statusCode}): ${response.body}");
      }
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("Exception Meta API: $e");
      return false;
    }
  }

  /// Méthode pour Green-API
  static Future<bool> sendGreenApiNotification({
    required String phone,
    required String studentName,
    required String dateAbsence,
    required String courseName,
    required String coursehour,
  }) async {
    print("Tentative d'envoi via Green-API...");
    print("ID Instance: ${AppConfig.greenApiIdInstance}");
    print("API Token: ${AppConfig.greenApiTokenInstance}");

    if (AppConfig.greenApiIdInstance.isEmpty ||
        AppConfig.greenApiTokenInstance.isEmpty ||
        AppConfig.greenApiIdInstance == 'TON_ID_INSTANCE') {
      print("Erreur: Identifiants Green-API non configurés ou invalides.");
      return false;
    }

    // Nettoyage radical : on ne garde QUE les chiffres
    String formattedPhone = phone.replaceAll(RegExp(r'[^0-9]'), '').trim();
    
    // Si le numéro commence par 00, on enlève les deux premiers zéros
    if (formattedPhone.startsWith('00')) {
      formattedPhone = formattedPhone.substring(2);
    }

    print("Numéro formaté final (chiffres uniquement): $formattedPhone");

    if (formattedPhone.isEmpty) {
      print("Erreur: Le numéro de téléphone est vide après nettoyage.");
      return false;
    }

    final url = Uri.parse(
      "https://api.green-api.com/waInstance${AppConfig.greenApiIdInstance}/sendMessage/${AppConfig.greenApiTokenInstance}",
    );

    final String message =
        "🔔 *NOTIFICATION D'ABSENCE*\n\n"
        "Bonjour cher parent,\n\n"
        "Nous vous informons que l'étudiant(e) *${studentName.toUpperCase()}* a été enregistré(e) *ABSENT(E)* lors de la séance suivante :\n\n"
        "📚 *Cours :* $courseName\n"
        "📅 *Date :* $dateAbsence\n"
        "🕒 *Horaire :* $coursehour\n\n"
        "Merci de prendre les dispositions nécessaires.\n\n"
        "_*La Surveillance Générale - PIGIER BÉNIN*_";

    final Map<String, dynamic> body = {
      "chatId": "$formattedPhone@c.us",
      "message": message,
    };

    print("JSON envoyé à Green-API: ${jsonEncode(body)}");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );
      if (response.statusCode != 200) {
        print("Erreur Green-API (${response.statusCode}): ${response.body}");
      }
      return response.statusCode == 200;
    } catch (e) {
      print("Exception Green-API: $e");
      return false;
    }
  }
}
