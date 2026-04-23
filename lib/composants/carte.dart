import 'package:flutter/material.dart';
import 'package:attendance/composants/colors.dart';

class Carte extends StatelessWidget {
  const Carte({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery.of(context).size.width > 600;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: isWide ? 600 : 420),
      child: GestureDetector(
        onTap: onTap,

        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: EdgeInsets.symmetric(
              vertical: isWide ? 35 : 28,
              horizontal: isWide ? 30 : 22,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: color,
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.white, size: 38),
                const SizedBox(width: 18),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: isWide ? 24 : 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.white,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


