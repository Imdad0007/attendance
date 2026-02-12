import 'package:flutter/material.dart';
import 'package:attendance/composants/colors.dart';

class DropdownField<T> extends StatelessWidget {
  const DropdownField({
    super.key,
    required this.value,
    required this.label,
    required this.items,
    required this.onChanged,
    this.disabled = false,
  });

  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        decoration: BoxDecoration(
          color: disabled ? Colors.grey.shade300 : AppColors.clearGrey,
          borderRadius: BorderRadius.circular(35),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            hint: Text(
              label,
              style: TextStyle(
                color: AppColors.grey[800],
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            isExpanded: true,
            borderRadius: BorderRadius.circular(20),
            icon: disabled
                ? const SizedBox.shrink()
                : const Icon(Icons.keyboard_arrow_down),
            items: items,
            onChanged: disabled ? null : onChanged,
          ),
        ),
      ),
    );
  }
}
