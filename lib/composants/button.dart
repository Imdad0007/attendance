import 'package:flutter/material.dart';
import 'package:attendance/composants/colors.dart';

class Button extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const Button({super.key, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      // color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(25),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          onTap: onPressed,
          child: Container(
            width: double.infinity,
            height: 50,
            alignment: Alignment.center,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
