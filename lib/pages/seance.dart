import 'package:flutter/material.dart';
import 'package:attendance/composants/colors.dart';
import 'package:attendance/composants/carte.dart';
import 'package:attendance/pages/onglet_seance/creer_seance.dart';
import 'package:attendance/pages/onglet_seance/suivre_seance.dart';

class Seance extends StatelessWidget {
  const Seance({super.key});

  @override
  Widget build(BuildContext context) {
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
                          'Programmer les séances',
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
                      color: Color(0xFF2E7D32),
                      onTap: () {
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
                      label: "Suivre les séances",
                      icon: Icons.list,
                      color: Color(0xFF1565C0),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SuivreSeance(),
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
