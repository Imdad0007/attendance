import 'package:flutter/material.dart';
import 'package:attendance/composants/colors.dart';

class Textfield extends StatelessWidget {
  final String hintText;
  final bool obscureText;
  final IconData icon;
  final TextEditingController? controller; // 1. Ajout du contrôleur

  const Textfield({
    super.key,
    required this.hintText,
    required this.obscureText,
    required this.icon,
    this.controller, // 2. Ajout au constructeur
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.deepGrey,
        borderRadius: BorderRadius.circular(25),
      ),
      child: TextField(
        controller: controller, // 3. Liaison avec le contrôleur
        obscureText: obscureText,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: AppColors.black),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 18,
            horizontal: 20,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 10, right: 15),
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
              ),
              child: Icon(icon, color: AppColors.white, size: 22),
            ),
          ),
          // Note : Le focusedBorder ne s'affichera que si le border n'est pas "none"
          // Si vous voulez garder le style actuel, le focus se gère souvent sur le Container parent.
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
      ),
    );
  }
}
