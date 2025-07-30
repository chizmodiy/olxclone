import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  // Heading-1
  static TextStyle get heading1Semibold => GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w600, // Semibold
        height: 1.2, // 120%
        letterSpacing: 0,
      );

  static TextStyle get heading1Medium => GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w500, // Medium
        height: 1.2, // 120%
        letterSpacing: 0,
      );

  static TextStyle get heading1Regular => GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w400, // Regular
        height: 1.2, // 120%
        letterSpacing: 0,
      );

  // Heading-2
  static TextStyle get heading2Semibold => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: 0,
      );

  static TextStyle get heading2Medium => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w500,
        height: 1.2,
        letterSpacing: 0,
      );

  static TextStyle get heading2Regular => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w400,
        height: 1.2,
        letterSpacing: 0,
      );

  // Heading-3
  static TextStyle get heading3Semibold => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.3, // 130%
        letterSpacing: 0,
      );

  static TextStyle get heading3Medium => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        height: 1.3, // 130%
        letterSpacing: 0,
      );

  static TextStyle get heading3Regular => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w400,
        height: 1.3, // 130%
        letterSpacing: 0,
      );

  // Body-1
  static TextStyle get body1Semibold => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.4, // 140%
        letterSpacing: 0.01 * 16, // 1% of font size
      );

  static TextStyle get body1Medium => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.4,
        letterSpacing: 0.01 * 16,
      );

  static TextStyle get body1MediumUnderlined => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.4,
        letterSpacing: 0.01 * 16,
        decoration: TextDecoration.underline,
      );

  static TextStyle get body1Regular => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.4,
        letterSpacing: 0.01 * 16,
      );

  // Body-2
  static TextStyle get body2Semibold => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.4,
        letterSpacing: 0.01 * 14,
      );

  static TextStyle get body2Medium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.4,
        letterSpacing: 0.01 * 14,
      );

  static TextStyle get body2MediumUnderlined => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.4,
        letterSpacing: 0.01 * 14,
        decoration: TextDecoration.underline,
      );

  static TextStyle get body2Regular => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.4,
        letterSpacing: 0.01 * 14,
      );

  // Caption
  static TextStyle get captionSemibold => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.3, // 130%
        letterSpacing: 0.02 * 12, // 2% of font size
      );

  static TextStyle get captionMedium => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.3,
        letterSpacing: 0.02 * 12,
      );

  static TextStyle get captionMediumUnderlined => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.3,
        letterSpacing: 0.02 * 12,
        decoration: TextDecoration.underline,
      );

  static TextStyle get captionRegularUppercase => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.3,
        letterSpacing: 0.02 * 12,
        // Flutter doesn't have a direct uppercase text transform in TextStyle.
        // This usually handled by Text widget or custom widget.
      );

  static TextStyle get captionRegular => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.3,
        letterSpacing: 0.02 * 12,
      );

  // Input Styles
  static InputDecoration get inputDecoration => InputDecoration(
    filled: true,
    fillColor: const Color(0xFFFAFAFA), // Zinc-50
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(200),
      borderSide: const BorderSide(
        width: 1,
        color: Color(0xFFE4E4E7), // Zinc-200
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(200),
      borderSide: const BorderSide(
        width: 1,
        color: Color(0xFFE4E4E7), // Zinc-200
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(200),
      borderSide: const BorderSide(
        width: 1,
        color: Color(0xFF015873), // Primary color
      ),
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 10,
    ),
    isDense: false,
    hintStyle: body1Regular.copyWith(
      color: const Color(0xFFA1A1AA), // Zinc-400
      letterSpacing: 0.16,
    ),
  );

  static InputDecoration get inputDecorationWithShadow => InputDecoration(
    filled: true,
    fillColor: const Color(0xFFFAFAFA), // Zinc-50
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(200),
      borderSide: const BorderSide(
        width: 1,
        color: Color(0xFFE4E4E7), // Zinc-200
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(200),
      borderSide: const BorderSide(
        width: 1,
        color: Color(0xFFE4E4E7), // Zinc-200
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(200),
      borderSide: const BorderSide(
        width: 1,
        color: Color(0xFF015873), // Primary color
      ),
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 10,
    ),
    isDense: false,
    hintStyle: body1Regular.copyWith(
      color: const Color(0xFFA1A1AA), // Zinc-400
      letterSpacing: 0.16,
    ),
  );

  // Container style for input with shadow
  static BoxDecoration get inputContainerDecoration => BoxDecoration(
    color: const Color(0xFFFAFAFA), // Zinc-50
    borderRadius: BorderRadius.circular(200),
    border: Border.all(
      width: 1,
      color: const Color(0xFFE4E4E7), // Zinc-200
    ),
    boxShadow: const [
      BoxShadow(
        color: Color(0x0C101828), // rgba(16, 24, 40, 0.05)
        blurRadius: 2,
        offset: Offset(0, 1),
        spreadRadius: 0,
      ),
    ],
  );
} 