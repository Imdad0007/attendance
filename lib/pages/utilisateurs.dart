import 'package:flutter/material.dart';
import 'package:attendance/composants/colors.dart';
import 'package:attendance/composants/carte.dart';
import 'package:attendance/pages/onglet_utilisateur/creer.dart';
import 'package:attendance/pages/onglet_utilisateur/supprimer.dart';
import 'package:attendance/pages/onglet_utilisateur/lister.dart';

class Creation extends StatelessWidget {
  const Creation({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                          'Gérer les utilisateurs',
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
                      label: "Créer un compte",
                      icon: Icons.person_add,
                      color: Color(0xFF2E7D32),
                      onTap: () {
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
                      color: Color(0xFF1565C0),
                      onTap: () {
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
                      label: "Supprimer un compte",
                      icon: Icons.delete,
                      color: Color(0xFFC62828),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const Supprimer(),
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
