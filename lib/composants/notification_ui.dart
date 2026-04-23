import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:attendance/composants/colors.dart';

enum NotificationType { success, error, info, warning }

class AppNotification {
  // Utilisation d'une NavigatorKey pour un accès global fiable à l'Overlay
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static OverlayEntry? _currentEntry;

  static void show({
    required String message,
    NotificationType type = NotificationType.info,
    String? debugMessage,
  }) {
    // Récupère l'état du navigateur pour trouver l'Overlay
    final navigatorState = navigatorKey.currentState;
    if (navigatorState == null) {
      debugPrint("AppNotification: navigatorState is null");
      return;
    }

    final overlay = navigatorState.overlay;
    if (overlay == null) {
      debugPrint("AppNotification: overlay is null");
      return;
    }

    final finalMessage = kReleaseMode
        ? message
        : (debugMessage != null
              ? "$message\n\n[DEBUG]: $debugMessage"
              : message);

    // Supprime l'ancienne notification proprement
    _currentEntry?.remove();
    _currentEntry = null;

    _currentEntry = OverlayEntry(
      builder: (context) => _NotificationOverlay(
        message: finalMessage,
        type: type,
        onDismiss: () {
          _currentEntry?.remove();
          _currentEntry = null;
        },
      ),
    );

    overlay.insert(_currentEntry!);

    // Auto-dismiss après 4 secondes
    Future.delayed(const Duration(seconds: 4), () {
      if (_currentEntry != null) {
        _currentEntry?.remove();
        _currentEntry = null;
      }
    });
  }

  static void success(String msg) =>
      show(message: msg, type: NotificationType.success);

  static void error(String msg, {dynamic error}) => show(
    message: msg,
    type: NotificationType.error,
    debugMessage: error?.toString(),
  );

  static void info(String msg) =>
      show(message: msg, type: NotificationType.info);

  static void warning(String msg) =>
      show(message: msg, type: NotificationType.warning);
}

class _NotificationOverlay extends StatefulWidget {
  final String message;
  final NotificationType type;
  final VoidCallback onDismiss;

  const _NotificationOverlay({
    required this.message,
    required this.type,
    required this.onDismiss,
  });

  @override
  State<_NotificationOverlay> createState() => _NotificationOverlayState();
}

class _NotificationOverlayState extends State<_NotificationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = _getStyle(widget.type);

    return Positioned(
      top: MediaQuery.of(context).padding.top + 20,
      left: 0,
      right: 0,
      child: Material(
        color: Colors.transparent,
        child: Center(
          child: SlideTransition(
            position: _offsetAnimation,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              constraints: const BoxConstraints(maxWidth: 500),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: style.color.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: style.color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(style.icon, color: style.color, size: 24),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getTitle(widget.type),
                          style: TextStyle(
                            color: style.color,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.message,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                    onPressed: widget.onDismiss,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getTitle(NotificationType type) {
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

  static ({IconData icon, Color color}) _getStyle(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return (icon: Icons.check_circle, color: Colors.green);
      case NotificationType.error:
        return (icon: Icons.error, color: AppColors.red);
      case NotificationType.warning:
        return (icon: Icons.warning, color: Colors.orange);
      case NotificationType.info:
        return (icon: Icons.info, color: AppColors.primary);
    }
  }
}
