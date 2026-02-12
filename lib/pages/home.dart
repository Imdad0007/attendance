import 'package:flutter/material.dart';
import 'package:attendance/composants/colors.dart';
import 'package:intl/intl.dart';
import 'package:attendance/providers/user_provider.dart';
import 'package:provider/provider.dart';

class HomePage extends StatelessWidget {
  final VoidCallback onStartCall;

  const HomePage({super.key, required this.onStartCall});

  // ================= DATE FORMATTEE =================
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
    final userProvider = Provider.of<UserProvider>(context);
    final String nomSurveillant =
        userProvider.user?.nomComplet ?? 'Utilisateur non connecté';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        child: Column(
          children: [

            // ================= DATE =================
            Text(
              todayDate,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'JetBrainsMono',
                fontSize: 18,
                color: Color.fromARGB(255, 125, 125, 125),
              ),
            ),

            const SizedBox(height: 60),

            // ================= BIENVENUE =================
            const Text(
              "Bienvenue,",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
              ),
            ),

            const SizedBox(height: 10),

            // ================= NOM =================
            Text(
              "M/Mme. $nomSurveillant",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 70),

            // ================= ACTION =================
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: GestureDetector(
                  onTap: onStartCall,
                  child: Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 28,
                        horizontal: 22,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: AppColors.secondaryGradient,
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.play_circle_outline,
                            color: AppColors.white,
                            size: 38,
                          ),
                          SizedBox(width: 18),
                          Expanded(
                            child: Text(
                              "Démarrer l’appel",
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: AppColors.white,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
