import 'package:flutter/material.dart';
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
