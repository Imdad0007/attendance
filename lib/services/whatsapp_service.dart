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
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
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
    if (AppConfig.greenApiIdInstance.isEmpty ||
        AppConfig.greenApiTokenInstance.isEmpty ||
        AppConfig.greenApiIdInstance == 'TON_ID_INSTANCE') {
      return false;
    }

    final formattedPhone = phone.replaceAll('+', '').replaceAll(' ', '').trim();
    final url = Uri.parse(
      "https://api.green-api.com/waInstance${AppConfig.greenApiIdInstance}/sendMessage/${AppConfig.greenApiTokenInstance}",
    );

    final String message =
        "🔔 *NOTIFICATION D'ABSENCE*\n\n"
        "Bonjour,\n\n"
        "Nous vous informons que l'étudiant(e) *${studentName.toUpperCase()}* a été enregistré(e) *ABSENT(E)* lors de la séance suivante :\n\n"
        "📚 *Cours :* $courseName\n"
        "📅 *Date :* $dateAbsence\n"
        "🕒 *Horaire :* $coursehour\n\n"
        "Merci de prendre les dispositions nécessaires.\n\n"
        "_*La Surveillance Générale - PIGIER BÉNIN*_";

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "chatId": "$formattedPhone@c.us",
          "message": message,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}


