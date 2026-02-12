import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class WhatsAppService {
  static const String phoneNumberId = "1001899229676106";
  static const String token = "EAAWdK9IJdl8BQq6mCZAsksvbr5fluRGmvVAWHbr2dCmYT5ZChZA1tFFjZBpRuUJ5WI6LnPCVqBeJEMuy4gVZASeQR2m1OWdOg2Jw7XZABSBjnqC6YR3eKK4hBtyPtjMIlldW1Ui0HcN1DhvI55VrpWmVlJwBY0kam2j2OOB8nZBCUKWpdadFyLK0XD9v6qiVb4n3HvtEpBHipzPcLx7el9ZAdY5q57L0BgKdH2eNF2xX8BUO1KsZBwVhnna4hJiZBabs8vKPMlqjZBWAk7UyQEDPDqhK9yh";

  static Future<bool> sendAbsenceTemplate({
    required String phone,
    required String studentName,
    required String dateAbsence,
    required String courseName,
    required String coursehour,
  }) async {
    final url = Uri.parse("https://graph.facebook.com/v19.0/$phoneNumberId/messages");

    // CRUCIAL : WhatsApp n'accepte pas le '+' dans le numéro de téléphone
    final formattedPhone = phone.replaceAll('+', '').replaceAll(' ', '').trim();

    try {
      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
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

      if (response.statusCode == 200) {
        debugPrint("WhatsApp Success: ${response.body}");
        return true;
      } else {
        debugPrint("WhatsApp API Error: Status ${response.statusCode} - Body: ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("WhatsApp Exception: $e");
      return false;
    }
  }
}