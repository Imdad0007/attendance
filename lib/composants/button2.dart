import 'package:flutter/material.dart';
import 'package:attendance/composants/colors.dart';

class Button2 extends StatelessWidget {
  final String label;
  final Gradient? gradient;
  final VoidCallback? onPressed;

  const Button2({
    super.key,
    required this.label,
    required this.gradient,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      // color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          gradient: onPressed == null ? null : gradient,
          color: onPressed == null
              ? AppColors.grey
              : null, // Use grey when disabled
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
              style: TextStyle(
                color: onPressed == null
                    ? AppColors.clearGrey
                    : Colors.white, // Lighter text when disabled
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


