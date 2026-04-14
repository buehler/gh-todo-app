import 'package:flutter/widgets.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:gh_todos/style/typography.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mix/mix.dart';

MixScope octanePrime(Widget child) => MixScope(
  colors: {
    ColorTokens.primary.$default: const Color(0xFF0051AE),
    ColorTokens.primary.container: const Color(0xFF0969DA),
    ColorTokens.primary.fixed: const Color(0xFFD8E2FF),
    ColorTokens.primary.on: const Color(0xFFFFFFFF),
    ColorTokens.primary.onFixedVariant: const Color(0xFF004493),
    ColorTokens.secondary.$default: const Color(0xFF5A5F66),
    ColorTokens.secondary.container: const Color(0xFFDEE3EB),
    ColorTokens.secondary.fixedDim: const Color(0xFFC2C7CF),
    ColorTokens.secondary.onFixedVariant: const Color(0xFF42474E),
    ColorTokens.tertiary.$default: const Color(0xFF913900),
    ColorTokens.tertiary.container: const Color(0xFFB84B00),
    ColorTokens.tertiary.fixedDim: const Color(0xFFFFB693),
    ColorTokens.tertiary.onContainer: const Color(0xFFFFECE5),
    ColorTokens.tertiary.onFixedVariant: const Color(0xFF7A2F00),
    ColorTokens.surface.$default: const Color(0xFFF7F9FF),
    ColorTokens.surface.bright: const Color(0xFFF7F9FF),
    ColorTokens.surface.containerLow: const Color(0xFFECF4FF),
    ColorTokens.surface.containerLowest: const Color(0xFFFFFFFF),
    ColorTokens.surface.containerHigh: const Color(0xFFE0E9F5),
    ColorTokens.surface.containerHighest: const Color(0xFFDAE3EF),
    ColorTokens.surface.on: const Color(0xFF141C25),
    ColorTokens.surface.onVariant: const Color(0xFF424753),
    ColorTokens.background.$default: const Color(0xFFF7F9FF),
    ColorTokens.background.on: const Color(0xFF141C25),
    ColorTokens.outline.$default: const Color(0xFF727785),
    ColorTokens.outline.variant: const Color(0xFFC2C6D6),
    ColorTokens.error.$default: const Color(0xFFBA1A1A),
    ColorTokens.error.container: const Color(0xFFFFDAD6),
    ColorTokens.error.onContainer: const Color(0xFF93000A),
    // Priority levels — see design/prio.html §07 Semantics.
    ColorTokens.priority.urgent.fg: const Color(0xFF93000A),
    ColorTokens.priority.urgent.bg: const Color(0xFFFFDAD6),
    ColorTokens.priority.high.fg: const Color(0xFFB84B00),
    ColorTokens.priority.high.bg: const Color(0xFFFFDBCC),
    ColorTokens.priority.medium.fg: const Color(0xFF725C00),
    ColorTokens.priority.medium.bg: const Color(0xFFFFE084),
    ColorTokens.priority.low.fg: const Color(0xFF42474E),
    ColorTokens.priority.low.bg: const Color(0xFFDEE3EB),
    ColorTokens.priority.trivial.fg: const Color(0xFF727785),
    ColorTokens.priority.trivial.bg: const Color(0xFFF0F1F5),
  },
  textStyles: {
    TextTokens.display.$large: GoogleFonts.manrope(
      fontSize: 48,
      fontWeight: FontWeight.w800,
      height: 1,
      letterSpacing: -1.4,
    ),
    TextTokens.headline.$medium: GoogleFonts.manrope(
      fontSize: 30,
      fontWeight: FontWeight.w700,
      height: 1.1,
      letterSpacing: -0.8,
    ),
    TextTokens.title.$large: GoogleFonts.manrope(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      height: 1.2,
      letterSpacing: -0.3,
    ),
    TextTokens.title.$medium: GoogleFonts.manrope(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      height: 1.2,
      letterSpacing: -0.2,
    ),
    TextTokens.title.$small: GoogleFonts.manrope(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.15,
      letterSpacing: -0.1,
    ),
    TextTokens.body.$large: GoogleFonts.inter(
      fontSize: 18,
      fontWeight: FontWeight.w400,
      height: 1.5,
    ),
    TextTokens.body.$medium: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.45,
    ),
    TextTokens.body.$small: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.4,
    ),
    TextTokens.label.$large: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.1,
    ),
    TextTokens.label.$medium: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      height: 1.1,
    ),
    TextTokens.label.$small: GoogleFonts.inter(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      height: 1,
    ),
  },
  child: child,
);
