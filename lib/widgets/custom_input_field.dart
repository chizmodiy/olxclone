import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_colors.dart';

class CustomInputField extends StatelessWidget {
  final TextEditingController controller;
  final String? hintText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? prefixIcon;
  final bool isDense;
  final EdgeInsetsGeometry? contentPadding;

  const CustomInputField({
    super.key,
    required this.controller,
    this.hintText,
    this.keyboardType,
    this.inputFormatters,
    this.prefixIcon,
    this.isDense = true,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    if (prefixIcon != null) {
      // Input with prefix icon (like phone number with country code)
      return Container(
        decoration: AppTextStyles.inputContainerDecoration,
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: prefixIcon!,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: keyboardType,
                inputFormatters: inputFormatters,
                decoration: InputDecoration(
                  hintText: hintText,
                  border: InputBorder.none,
                  isDense: isDense,
                  contentPadding: contentPadding ?? const EdgeInsets.symmetric(vertical: 10),
                ),
                style: AppTextStyles.body1Regular.copyWith(color: AppColors.color2),
              ),
            ),
          ],
        ),
      );
    } else {
      // Simple input without prefix
      return TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        decoration: AppTextStyles.inputDecoration.copyWith(
          hintText: hintText,
          contentPadding: contentPadding,
        ),
        style: AppTextStyles.body1Regular.copyWith(color: AppColors.color2),
      );
    }
  }
} 