import 'package:flutter/material.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:gh_todos/style/typography.dart';
import 'package:mix/mix.dart';

const editorialInteractionDuration = Duration(milliseconds: 180);
final editorialAnimation = AnimationConfig.easeOutCubic(
  editorialInteractionDuration,
);

const double editorialRadiusSmall = 12;
const double editorialRadiusMedium = 16;
const double editorialRadiusLarge = 24;

Color withOpacity(Color color, double opacity) {
  return color.withAlpha((255 * opacity).round());
}

Color resolveColor(BuildContext context, ColorToken token) {
  return token.resolve(context);
}

TextStyle resolveTextStyle(BuildContext context, TextStyleToken token) {
  return token.resolve(context);
}

TextStyler editorialTextStyle(
  TextStyleToken token, {
  required Color color,
  double? letterSpacing,
  FontWeight? fontWeight,
  List<FontFeature>? fontFeatures,
}) {
  var style = TextStyler().style(token.mix()).color(color);

  if (letterSpacing != null) {
    style = style.letterSpacing(letterSpacing);
  }

  if (fontWeight != null) {
    style = style.fontWeight(fontWeight);
  }

  if (fontFeatures != null) {
    style = style.fontFeatures(fontFeatures);
  }

  return style;
}

IconStyler editorialIconStyle({required Color color, required double size}) {
  return IconStyler().color(color).size(size);
}

BoxShadowMix editorialShadow({
  required Color color,
  required double blurRadius,
  required double yOffset,
  double spreadRadius = 0,
}) {
  return BoxShadowMix(
    color: color,
    offset: Offset(0, yOffset),
    blurRadius: blurRadius,
    spreadRadius: spreadRadius,
  );
}

/// Base column layout styler for a [ColumnBox].
///
/// [ColumnBox] already forces [Axis.vertical], so we deliberately skip
/// [FlexStyler.direction]. Callers can still `.merge()` this with extra
/// properties (constraints, padding, etc.) without fighting an opinionated
/// direction setting.
FlexBoxStyler editorialColumnStyle({
  required double spacing,
  CrossAxisAlignment crossAxis = CrossAxisAlignment.start,
  MainAxisAlignment mainAxis = MainAxisAlignment.start,
  MainAxisSize mainAxisSize = MainAxisSize.min,
  double? width,
}) {
  var style = FlexBoxStyler().flex(
    FlexStyler()
        .crossAxisAlignment(crossAxis)
        .mainAxisAlignment(mainAxis)
        .mainAxisSize(mainAxisSize)
        .spacing(spacing),
  );
  if (width != null) {
    style = style.width(width);
  }
  return style;
}

/// Base row layout styler for a [RowBox].
///
/// [RowBox] already forces [Axis.horizontal], so we deliberately skip
/// [FlexStyler.direction].
FlexBoxStyler editorialRowStyle({
  required double spacing,
  CrossAxisAlignment crossAxis = CrossAxisAlignment.center,
  MainAxisAlignment mainAxis = MainAxisAlignment.start,
  MainAxisSize mainAxisSize = MainAxisSize.min,
}) {
  return FlexBoxStyler().flex(
    FlexStyler()
        .crossAxisAlignment(crossAxis)
        .mainAxisAlignment(mainAxis)
        .mainAxisSize(mainAxisSize)
        .spacing(spacing),
  );
}

StackBoxStyler setupPageStackStyle() {
  return StackBoxStyler().stack(
    StackStyler().fit(StackFit.expand).clipBehavior(Clip.none),
  );
}

BoxStyler setupPageBackgroundStyle(BuildContext context) {
  return BoxStyler().linearGradient(
    colors: [
      resolveColor(context, ColorTokens.surface.bright),
      resolveColor(context, ColorTokens.surface.$default),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

BoxStyler setupPageContentFrameStyle() {
  return BoxStyler()
      .constraints(BoxConstraintsMix.maxWidth(560))
      .width(double.infinity)
      .margin(EdgeInsetsMix.symmetric(horizontal: 24, vertical: 24))
      .onTablet(
        BoxStyler().margin(
          EdgeInsetsMix.symmetric(horizontal: 48, vertical: 36),
        ),
      );
}

FlexBoxStyler setupPageContentColumnStyle() {
  return FlexBoxStyler()
      .flex(
        FlexStyler()
            .direction(Axis.vertical)
            .crossAxisAlignment(CrossAxisAlignment.start)
            .mainAxisSize(MainAxisSize.min)
            .spacing(20),
      )
      .onTablet(FlexBoxStyler().flex(FlexStyler().spacing(24)));
}

BoxStyler editorialTextFieldShellStyle(
  BuildContext context, {
  required bool isFocused,
  required bool hasError,
}) {
  final outlineVariant = resolveColor(context, ColorTokens.outline.variant);
  final primaryFixed = resolveColor(context, ColorTokens.primary.fixed);
  final surfaceLow = resolveColor(context, ColorTokens.surface.containerLow);
  final surfaceLowest = resolveColor(
    context,
    ColorTokens.surface.containerLowest,
  );
  final error = resolveColor(context, ColorTokens.error.$default);

  final borderColor = hasError
      ? withOpacity(error, 0.42)
      : isFocused
      ? primaryFixed
      : withOpacity(outlineVariant, 0.22);

  final shadow = hasError
      ? editorialShadow(
          color: withOpacity(error, 0.08),
          blurRadius: 14,
          yOffset: 0,
        )
      : isFocused
      ? editorialShadow(
          color: withOpacity(primaryFixed, 0.38),
          blurRadius: 18,
          yOffset: 0,
        )
      : editorialShadow(
          color: withOpacity(outlineVariant, 0.06),
          blurRadius: 12,
          yOffset: 0,
        );

  return BoxStyler()
      .color(isFocused ? surfaceLowest : surfaceLow)
      .borderRounded(editorialRadiusSmall)
      .paddingOnly(horizontal: 16, vertical: 14)
      .animate(editorialAnimation)
      .borderAll(
        color: borderColor,
        width: isFocused ? 2 : (hasError ? 1.5 : 1),
      )
      .shadow(shadow);
}

BoxStyler editorialTextLinkStyle(
  BuildContext context, {
  required bool enabled,
}) {
  final primary = resolveColor(context, ColorTokens.primary.$default);

  var style = BoxStyler()
      .color(Colors.transparent)
      .borderRounded(999)
      .padding(EdgeInsetsMix.symmetric(horizontal: 4, vertical: 4))
      .animate(editorialAnimation);

  if (!enabled) {
    return style.onDisabled(BoxStyler().color(Colors.transparent));
  }

  return style
      .onHovered(BoxStyler().color(withOpacity(primary, 0.06)))
      .onPressed(BoxStyler().color(withOpacity(primary, 0.1)).scale(0.98));
}

FlexBoxStyler editorialTextLinkRowStyle({
  MainAxisSize mainAxisSize = MainAxisSize.min,
}) {
  return FlexBoxStyler().flex(
    FlexStyler()
        .direction(Axis.horizontal)
        .crossAxisAlignment(CrossAxisAlignment.center)
        .mainAxisSize(mainAxisSize)
        .spacing(6),
  );
}

TextStyler editorialTextLinkTextStyle(
  BuildContext context, {
  required bool enabled,
}) {
  final primary = resolveColor(context, ColorTokens.primary.$default);
  final onSurfaceVariant = resolveColor(context, ColorTokens.surface.onVariant);

  return editorialTextStyle(
    TextTokens.label.$large,
    color: enabled ? primary : onSurfaceVariant,
    fontWeight: FontWeight.w600,
  );
}
