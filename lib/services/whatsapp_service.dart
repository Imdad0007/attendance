import 'dart:convert';
import 'package:attendance/config/app_config.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class WhatsAppService {
  /// Nettoie et formate le numéro de téléphone pour WhatsApp
  static String _formatPhone(String phone) {
    // On garde le numéro tel quel (juste les chiffres) car la BDD est déjà correcte
    return phone.replaceAll(RegExp(r'[^0-9]'), '').trim();
  }

  /// Ouvre WhatsApp directement sur l'appareil avec le message pré-rempli
  static Future<void> launchWhatsAppDirectly({
    required String phone,
    required String message,
  }) async {
    final formattedPhone = _formatPhone(phone);
    final Uri url = Uri.parse(
      "https://wa.me/$formattedPhone?text=${Uri.encodeComponent(message)}",
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      print("Impossible d'ouvrir WhatsApp pour le numéro: $formattedPhone");
    }
  }

  /// Envoie la notification via Meta ET la Passerelle Locale en PARALLÈLE
  static Future<bool> sendAbsenceTemplate({
    required String phone,
    required String studentName,
    required String dateAbsence,
    required String courseName,
    required String coursehour,
  }) async {
    // 1. Construction du message texte pour la passerelle locale
    final String textMessage =
        "*NOTIFICATION D'ABSENCE*\n\n"
        "Bonjour cher parent,\n\n"
        "Nous vous informons que l'étudiant(e) *${studentName.toUpperCase()}* est *ABSENT(E)* lors de la séance de cours suivante :\n\n"
        "*Cours :*  $courseName\n"
        "*Date :*  $dateAbsence\n"
        "*Horaire :*  $coursehour\n\n"
        "Merci de prendre les dispositions nécessaires.\n\n\n"
        "*La Surveillance Générale* ✍🏻";

    // 2. Lancement des deux envois en parallèle
    final results = await Future.wait([
      sendLocalGatewayNotification(
        phone: _formatPhone(phone),
        message: textMessage,
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

  /// Méthode pour Meta API (Templates officiels)
  static Future<bool> sendMetaApiNotification({
    required String phone,
    required String studentName,
    required String dateAbsence,
    required String courseName,
    required String coursehour,
  }) async {
    // Trim des identifiants pour éviter les espaces invisibles venant de la config
    final String phoneId = AppConfig.whatsappPhoneNumberId.trim();
    final String token = AppConfig.whatsappToken.trim();

    if (phoneId.isEmpty || token.isEmpty) {
      return false;
    }

    final url = Uri.parse(
      "https://graph.facebook.com/v19.0/$phoneId/messages",
    );
    
    // Nettoyage rigoureux : Meta n'accepte QUE les chiffres (pas de +, pas d'espaces, pas de tabs)
    final formattedPhone = phone.replaceAll(RegExp(r'[^0-9]'), '').trim();

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
      if (response.statusCode != 200 && response.statusCode != 201) {
        print("Erreur Meta API (${response.statusCode}): ${response.body}");
      }
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("Exception Meta API: $e");
      return false;
    }
  }
  /// Méthode pour la passerelle locale Node.js
  static Future<bool> sendLocalGatewayNotification({
    required String phone,
    required String message,
  }) async {
    if (AppConfig.localGatewayUrl.isEmpty) return false;

    // Construction robuste de l'URL pour s'assurer de pointer sur /send-message
    String baseUrl = AppConfig.localGatewayUrl.trim();
    if (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }
    final gatewayUrl = "$baseUrl/send-message";

    try {
      final url = Uri.parse(gatewayUrl);

      final response = await http
          .post(
            url,
            headers: {
              "Content-Type": "application/json",
              "ngrok-skip-browser-warning": "true",
            },
            body: jsonEncode({"phone": phone, "message": message}),
          )
          .timeout(const Duration(seconds: 15));

      print(
        "Réponse passerelle locale: ${response.statusCode} - ${response.body}",
      );

      if (response.statusCode == 200) {
        print("Message envoyé avec succès via la Passerelle Locale");
        return true;
      }
      print(
        "Échec passerelle locale (${response.statusCode}): ${response.body}",
      );
      return false;
    } catch (e) {
      print("Passerelle locale non détectée ou erreur: $e");
      return false;
    }
  }
}
