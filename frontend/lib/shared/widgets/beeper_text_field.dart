// 공통 입력 필드 (surface 배경, 포커스 시 primary 테두리)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/theme.dart';

class BeeperTextField extends StatelessWidget {
  const BeeperTextField({
    super.key,
    required this.controller,
    this.label,
    this.hintText,
    this.obscureText = false,
    this.keyboardType,
    this.inputFormatters,
    this.errorText,
    this.maxLength,
    this.maxLines = 1,
    this.minLines,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String? label;
  final String? hintText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? errorText;
  final int? maxLength;
  final int? maxLines;
  final int? minLines;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: BeeperTypography.bodyMedium),
          const SizedBox(height: BeeperSpacing.s8),
        ],
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLength: maxLength,
          maxLines: maxLines,
          minLines: minLines,
          onChanged: onChanged,
          onTap: onTap,
          readOnly: readOnly,
          style: BeeperTypography.bodyLarge,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: BeeperTypography.bodyLarge.copyWith(
              color: BeeperColors.textPrimary.withValues(alpha: 0.4),
            ),
            filled: true,
            fillColor: BeeperColors.surface,
            counterText: '',
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: BeeperSpacing.s16,
              vertical: BeeperSpacing.s16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(BeeperRadius.card),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(BeeperRadius.card),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(BeeperRadius.card),
              borderSide: const BorderSide(
                color: BeeperColors.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(BeeperRadius.card),
              borderSide: const BorderSide(color: BeeperColors.error),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: BeeperSpacing.s8),
          Text(
            errorText!,
            style: BeeperTypography.labelSmall.copyWith(
              color: BeeperColors.error,
            ),
          ),
        ],
      ],
    );
  }
}
