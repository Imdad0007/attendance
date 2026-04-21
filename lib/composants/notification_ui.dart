import 'package:flutter/material.dart';
import 'package:attendance/composants/colors.dart';
import 'package:flutter/foundation.dart';

enum NotificationType { success, error, info, warning }

class AppNotification {
  // Clé globale pour afficher des notifications n'importe où sans context
  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static void show({
    required String message,
    NotificationType type = NotificationType.info,
    String? debugMessage,
  }) {
    final String finalMessage = kReleaseMode
        ? message
        : (debugMessage != null
              ? "$message\n\n[DEBUG]: $debugMessage"
              : message);

    final state = messengerKey.currentState;
    if (state == null) return;

    state.removeCurrentSnackBar();

    state.showSnackBar(
      SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        duration: const Duration(seconds: 3),
        content: _NotificationCard(message: finalMessage, type: type),
      ),
    );
  }

  static void success(String message) =>
      show(message: message, type: NotificationType.success);

  static void error(String message, {dynamic error}) => show(
    message: message,
    type: NotificationType.error,
    debugMessage: error?.toString(),
  );

  static void info(String message) =>
      show(message: message, type: NotificationType.info);

  static void warning(String message) =>
      show(message: message, type: NotificationType.warning);
}

class _NotificationCard extends StatelessWidget {
  final String message;
  final NotificationType type;

  const _NotificationCard({required this.message, required this.type});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color baseColor;
    LinearGradient gradient;

    switch (type) {
      case NotificationType.success:
        icon = Icons.check_circle_rounded;
        baseColor = Colors.green.shade600;
        gradient = AppColors.greenGradient;
        break;
      case NotificationType.error:
        icon = Icons.error_rounded;
        baseColor = AppColors.red;
        gradient = LinearGradient(
          colors: [AppColors.red, AppColors.red.withOpacity(0.8)],
        );
        break;
      case NotificationType.warning:
        icon = Icons.warning_rounded;
        baseColor = Colors.orange.shade700;
        gradient = const LinearGradient(
          colors: [Colors.orange, Colors.deepOrange],
        );
        break;
      case NotificationType.info:
        icon = Icons.info_rounded;
        baseColor = AppColors.primary;
        gradient = AppColors.primaryGradient;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: baseColor.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: baseColor.withOpacity(0.1), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: gradient,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getTitle(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: baseColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: const TextStyle(color: AppColors.black, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTitle() {
    switch (type) {
      case NotificationType.success:
        return "Succès";
      case NotificationType.error:
        return "Erreur";
      case NotificationType.warning:
        return "Attention";
      case NotificationType.info:
        return "Information";
    }
  }
}
