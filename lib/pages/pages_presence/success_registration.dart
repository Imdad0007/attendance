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
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animation ou Icône de succès avec effet d'ombre
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.05),
                          blurRadius: 20,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF16A34A),
                        size: 100,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Titre Principal
                  const Text(
                    "Enregistrement Terminé",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E293B),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Texte de succès formaté
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "Le contrôle de présence a été effectué avec succès.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF334155),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              failedNotifications == 0 
                                ? Icons.done_all_rounded 
                                : Icons.info_outline_rounded,
                              size: 20,
                              color: failedNotifications == 0 ? Colors.green : Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                failedNotifications == 0
                                    ? "Toutes les notifications d'absence ont été envoyées."
                                    : "Présence enregistrée, mais $failedNotifications notification(s) ont échoué.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: const Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 60),

                  // Bouton de retour
                  SizedBox(
                    width: double.infinity,
                    child: Button(
                      label: "TERMINER",
                      onPressed: closeSuccess,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
