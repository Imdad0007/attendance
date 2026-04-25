import 'package:flutter/material.dart';
import 'package:attendance/composants/colors.dart';
import 'package:attendance/composants/button.dart';
import 'package:attendance/config/adaptive_layout.dart';
import 'package:go_router/go_router.dart';

import 'package:attendance/providers/navigation_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SuccessRegistration extends ConsumerWidget {
  final int failedNotifications;

  const SuccessRegistration({super.key, required this.failedNotifications});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final useAdaptiveNavigation = useMainLayoutRail(context);

    void closeSuccess() {
      ref.read(navigationTabProvider.notifier).state = AppTab.presence;
      ref.read(adaptiveNavigationProvider.notifier).state =
          const AdaptiveNavigationState.none();

      if (!useAdaptiveNavigation) {
        context.go('/');
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF0F2F5),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.black),
          onPressed: closeSuccess,
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 40.0,
                vertical: 20,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.green,
                      size: 120,
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    "ENREGISTREMENT RÉUSSI",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    failedNotifications == 0
                        ? "La présence a été enregistrée avec succès. Toutes les notifications ont été envoyées."
                        : "La présence a été enregistrée, mais $failedNotifications notification(s) WhatsApp n'ont pas pu être envoyées.",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      color: AppColors.grey,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 60),
                  Button(label: "TERMINER", onPressed: closeSuccess),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
