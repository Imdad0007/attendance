import 'package:flutter/material.dart';
import 'package:attendance/composants/colors.dart';
import 'package:attendance/composants/button.dart';
import 'package:go_router/go_router.dart';

class SuccessRegistration extends StatelessWidget {
  final int failedNotifications;

  const SuccessRegistration({
    super.key,
    required this.failedNotifications,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.black),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
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
                  fontSize: 24,
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
                  fontSize: 16,
                  color: AppColors.grey,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 60),
              Button(
                label: "TERMINER",
                onPressed: () => context.go('/'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
