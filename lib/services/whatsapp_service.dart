import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class WhatsAppService {
  static const String phoneNumberId = "1001899229676106";
  static const String token = "EAAWdK9IJdl8BQo1WrzXiIQCcDugIKqOopK0cvZCOxYZC9uc3Y2hVLNgEubhlxEQE0PqywPfu2atGbpP5ZB7q3umuUh1uKfuJNl5Yioojub0luqOETXFnzJ2nyrZBn2LwgdeELD2XzGb5nAB2tFzCtaN7JYgCx3oah3xKNgishUmBQrye9ORySGun3fDtY89S0gZDZD";

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