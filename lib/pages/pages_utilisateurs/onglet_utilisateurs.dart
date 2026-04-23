import 'package:attendance/composants/carte.dart';
import 'package:attendance/composants/colors.dart';
import 'package:attendance/config/adaptive_layout.dart';
import 'package:attendance/pages/pages_utilisateurs/creer_seance.dart';
import 'package:attendance/pages/pages_utilisateurs/lister.dart';
import 'package:attendance/pages/pages_utilisateurs/retirer.dart';
import 'package:attendance/providers/navigation_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Utilisateur extends ConsumerWidget {
  const Utilisateur({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final useAdaptiveNavigation = useMainLayoutRail(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final verticalSpacing = constraints.maxHeight * 0.03;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          'Gerer les utilisateurs',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.black,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: verticalSpacing * 2),
                    Carte(
                      label: "Creer un compte",
                      icon: Icons.person_add,
                      color: const Color(0xFF2E7D32),
                      onTap: () {
                        if (useAdaptiveNavigation) {
                          ref
                              .read(adaptiveNavigationProvider.notifier)
                              .state = const AdaptiveNavigationState(
                            page: AdaptivePage.creerUtilisateur,
                          );
                          return;
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const Creer(),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: verticalSpacing),
                    Carte(
                      label: "Lister les surveillants",
                      icon: Icons.list,
                      color: const Color(0xFF1565C0),
                      onTap: () {
                        if (useAdaptiveNavigation) {
                          ref
                              .read(adaptiveNavigationProvider.notifier)
                              .state = const AdaptiveNavigationState(
                            page: AdaptivePage.listerUtilisateurs,
                          );
                          return;
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const Lister(),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: verticalSpacing),
                    Carte(
                      label: "Retirer un compte",
                      icon: Icons.delete,
                      color: const Color(0xFFC62828),
                      onTap: () {
                        if (useAdaptiveNavigation) {
                          ref
                              .read(adaptiveNavigationProvider.notifier)
                              .state = const AdaptiveNavigationState(
                            page: AdaptivePage.retirerUtilisateur,
                          );
                          return;
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const Retirer(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
