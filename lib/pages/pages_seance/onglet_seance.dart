import 'package:attendance/composants/carte.dart';
import 'package:attendance/composants/colors.dart';
import 'package:attendance/config/adaptive_layout.dart';
import 'package:attendance/pages/pages_seance/creer_seance.dart';
import 'package:attendance/pages/pages_seance/consulter_seance.dart';
import 'package:attendance/providers/navigation_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Seance extends ConsumerWidget {
  const Seance({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final useAdaptiveNavigation = useMainLayoutRail(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final verticalSpacing = constraints.maxHeight * 0.03;
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Text(
                              'Plannifier les séances',
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
                          label: "Créer une séance",
                          icon: Icons.person_add,
                          color: const Color(0xFF2E7D32),
                          onTap: () {
                            if (useAdaptiveNavigation) {
                              ref
                                  .read(adaptiveNavigationProvider.notifier)
                                  .state = const AdaptiveNavigationState(
                                page: AdaptivePage.creerSeance,
                                extra: {'mode': 'create'},
                              );
                              return;
                            }

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const CreerSeance(mode: 'create'),
                              ),
                            );
                          },
                        ),
                        SizedBox(height: verticalSpacing * 2),
                        Carte(
                          label: "Consulter les séances",
                          icon: Icons.list,
                          color: const Color(0xFF1565C0),
                          onTap: () {
                            if (useAdaptiveNavigation) {
                              ref
                                  .read(adaptiveNavigationProvider.notifier)
                                  .state = const AdaptiveNavigationState(
                                page: AdaptivePage.consulterSeance,
                              );
                              return;
                            }

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ConsulterSeance(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
