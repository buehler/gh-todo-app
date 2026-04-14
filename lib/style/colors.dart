import 'package:mix/mix.dart';

class ColorTokens {
  static const primary = _PrimaryColorTokens._();
  static const secondary = _SecondaryColorTokens._();
  static const tertiary = _TertiaryColorTokens._();
  static const surface = _SurfaceColorTokens._();
  static const background = _BackgroundColorTokens._();
  static const outline = _OutlineColorTokens._();
  static const error = _ErrorColorTokens._();
  static const priority = _PriorityColorTokens._();

  const ColorTokens._();
}

class _PrimaryColorTokens {
  final $default = const ColorToken('color.primary.default');
  final container = const ColorToken('color.primary.container');
  final fixed = const ColorToken('color.primary.fixed');
  final on = const ColorToken('color.primary.on');
  final onFixedVariant = const ColorToken('color.primary.on-fixed-variant');

  const _PrimaryColorTokens._();
}

class _SecondaryColorTokens {
  final $default = const ColorToken('color.secondary.default');
  final container = const ColorToken('color.secondary.container');
  final fixedDim = const ColorToken('color.secondary.fixed-dim');
  final onFixedVariant = const ColorToken('color.secondary.on-fixed-variant');

  const _SecondaryColorTokens._();
}

class _TertiaryColorTokens {
  final $default = const ColorToken('color.tertiary.default');
  final container = const ColorToken('color.tertiary.container');
  final fixedDim = const ColorToken('color.tertiary.fixed-dim');
  final onContainer = const ColorToken('color.tertiary.on-container');
  final onFixedVariant = const ColorToken('color.tertiary.on-fixed-variant');

  const _TertiaryColorTokens._();
}

class _SurfaceColorTokens {
  final $default = const ColorToken('color.surface.default');
  final bright = const ColorToken('color.surface.bright');
  final containerLow = const ColorToken('color.surface.container-low');
  final containerLowest = const ColorToken('color.surface.container-lowest');
  final containerHigh = const ColorToken('color.surface.container-high');
  final containerHighest = const ColorToken('color.surface.container-highest');
  final on = const ColorToken('color.surface.on');
  final onVariant = const ColorToken('color.surface.on-variant');

  const _SurfaceColorTokens._();
}

class _BackgroundColorTokens {
  final $default = const ColorToken('color.background.default');
  final on = const ColorToken('color.background.on');

  const _BackgroundColorTokens._();
}

class _OutlineColorTokens {
  final $default = const ColorToken('color.outline.default');
  final variant = const ColorToken('color.outline.variant');

  const _OutlineColorTokens._();
}

class _ErrorColorTokens {
  final $default = const ColorToken('color.error.default');
  final container = const ColorToken('color.error.container');
  final onContainer = const ColorToken('color.error.on-container');

  const _ErrorColorTokens._();
}

/// Semantic color tokens for the 5 priority levels, per `design/prio.html` §07.
///
/// Each level exposes a `fg` (strong tone — used for the dot and label text)
/// and a `bg` (pill fill). Values are defined in the theme, not inline.
class _PriorityColorTokens {
  final urgent = const PriorityLevelTokens(
    fg: ColorToken('color.priority.urgent.fg'),
    bg: ColorToken('color.priority.urgent.bg'),
  );
  final high = const PriorityLevelTokens(
    fg: ColorToken('color.priority.high.fg'),
    bg: ColorToken('color.priority.high.bg'),
  );
  final medium = const PriorityLevelTokens(
    fg: ColorToken('color.priority.medium.fg'),
    bg: ColorToken('color.priority.medium.bg'),
  );
  final low = const PriorityLevelTokens(
    fg: ColorToken('color.priority.low.fg'),
    bg: ColorToken('color.priority.low.bg'),
  );
  final trivial = const PriorityLevelTokens(
    fg: ColorToken('color.priority.trivial.fg'),
    bg: ColorToken('color.priority.trivial.bg'),
  );

  const _PriorityColorTokens._();
}

class PriorityLevelTokens {
  final ColorToken fg;
  final ColorToken bg;

  const PriorityLevelTokens({required this.fg, required this.bg});
}
