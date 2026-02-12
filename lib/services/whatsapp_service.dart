import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class WhatsAppService {
  static const String phoneNumberId = "1001899229676106";
  static const String token =
      "EAAUfadYaUJEBQqiBQGOZBJEIVoSr9JZAHtxQzPvgAvswUfk5PZCvMKlEGc51kRhh7a3zSztZAZBD50rO9XH4XpRaziOs1nEyKLadvxe8B0cbLV6umlNXeREqUSWDUhpJYZAY41ZB5Pct0qYiEr1fhJnkTeDoFr0MK23X8VGY3c3hp0yStJH4WcxbT5GQZCCQe2fN49P5D8IXX2d0uGwIyvVosHTJr7dneuUTZCLfJxmbb";

  static Future<bool> sendAbsenceTemplate({
    required String phone,
    required String studentName,
    required String dateAbsence,
    required String courseName,
    required String coursehour,
  }) async {
    final url = Uri.parse(
      "https://graph.facebook.com/v19.0/$phoneNumberId/messages",
    );

    try {
      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "messaging_product": "whatsapp",
          "to": phone,
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

      if (response.statusCode == 200) {
        debugPrint("WhatsApp message sent successfully to $phone");
        return true;
      } else {
        debugPrint(
          "Failed to send WhatsApp message to $phone. Status: ${response.statusCode}, Body: ${response.body}",
        );
        return false;
      }
    } catch (e) {
      debugPrint("Error sending WhatsApp message to $phone: $e");
      return false;
    }
  }
}
