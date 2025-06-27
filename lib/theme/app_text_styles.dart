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
} 