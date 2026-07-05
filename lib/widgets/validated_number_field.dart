import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

class ValidatedNumberField extends StatelessWidget {
  const ValidatedNumberField({
    super.key,
    required this.controller,
    required this.label,
    this.hintText,
    this.suffixText,
    this.showError = false,
    this.errorText = 'Bu alan zorunludur',
    this.decimal = false,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String? hintText;
  final String? suffixText;
  final bool showError;
  final String errorText;
  final bool decimal;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          keyboardType: decimal
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.number,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            labelText: label,
            hintText: hintText,
            suffixText: suffixText,
            errorText: showError ? errorText : null,
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

String formatSavedInt(int value) => value > 0 ? value.toString() : '';

String formatSavedDouble(double value, {int decimals = 1}) {
  if (value <= 0) return '';
  if (decimals == 0 || value == value.roundToDouble()) {
    return value.round().toString();
  }
  return value.toStringAsFixed(decimals);
}

Widget fieldErrorText(String message) {
  return Padding(
    padding: const EdgeInsets.only(top: 6, left: 4),
    child: Text(
      message,
      style: GoogleFonts.inter(fontSize: 12, color: AppColors.accent),
    ),
  );
}
