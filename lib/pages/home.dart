import 'package:flutter/material.dart';
import 'package:attendance/composants/colors.dart';
import 'package:intl/intl.dart';
import 'package:attendance/providers/user_provider.dart';
import 'package:provider/provider.dart';

class HomePage extends StatelessWidget {
  final VoidCallback onStartCall; // Callback pour changer d'onglet

  const HomePage({super.key, required this.onStartCall});


  String get todayDate {
    final now = DateTime.now();
    final date = DateFormat("EEEE d MMMM y", "fr_FR").format(now);
    return date
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {

    // 1. Accéder au UserProvider
    final userProvider = Provider.of<UserProvider>(context);

    // 2. Utiliser les données de l'utilisateur
    // On utilise 'user?.nomComplet' pour éviter une erreur si l'utilisateur est null.
    final String nomSurveillant = userProvider.user?.nomComplet ?? 'Utilisateur non connecté';


    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          Center(
            child: Text(
            "Aujourd’hui : $todayDate",
            style: const TextStyle(
              fontFamily: 'JetBrainsMono',
              color: Color.fromARGB(255, 125, 125, 125),
              fontSize: 18,
            ),
          ),
          ),

          const SizedBox(height: 90),
          Center(
            child: const Text("Bienvenue,", style: TextStyle(fontSize: 25,)),
          ),
          const SizedBox(height: 10),
          
          Center(
            child: Text(
            "M/Mme. $nomSurveillant",
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
          ),
          ),

          const SizedBox(height: 40),

          const SizedBox(height: 16),

          Center(
            child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: GestureDetector(
              onTap:
                  onStartCall, // Déclenche le changement d'onglet vers Presence
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: AppColors.secondaryGradient,
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: AppColors.white,
                        size: 32,
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          "Démarrer l’appel",
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: AppColors.white,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          )
        ],
      ),
    );
  }
}
