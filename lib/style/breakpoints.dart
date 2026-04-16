import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';

/// Width thresholds driving the app's responsive behaviour.
///
/// ```
/// compact   < 600   — phone portrait / landscape
/// medium   600–899  — iPad portrait (834), foldables, phone landscape
/// expanded 900–1279 — iPad landscape (1194), small desktop windows
/// large    ≥ 1280   — desktop full-screen; triggers connect decoration
/// ```
///
/// `isWide` (≥ 900) is the single predicate that flips the shell from
/// bottom-tab + push to side-rail + split.
const double kCompactMax = 600;
const double kMediumMax = 900;
const double kExpandedMax = 1280;

const Breakpoint appCompactBp = Breakpoint(maxWidth: kCompactMax - 1);
const Breakpoint appMediumBp = Breakpoint(
  minWidth: kCompactMax,
  maxWidth: kMediumMax - 1,
);
const Breakpoint appExpandedBp = Breakpoint(
  minWidth: kMediumMax,
  maxWidth: kExpandedMax - 1,
);
const Breakpoint appLargeBp = Breakpoint(minWidth: kExpandedMax);

/// Overrides Mix's default mobile/tablet/desktop thresholds so existing
/// `.onTablet()` / `.onDesktop()` call sites (e.g. `setupPageContentFrameStyle`)
/// reflect this app's tiers.
final Map<BreakpointToken, Breakpoint> appBreakpoints = {
  BreakpointToken.mobile: appCompactBp,
  BreakpointToken.tablet: appMediumBp,
  BreakpointToken.desktop: appExpandedBp,
};

/// Imperative helpers for code that can't use Mix variants (e.g. `if`-branches
/// in widget trees or route builders).
bool isCompact(BuildContext context) =>
    MediaQuery.sizeOf(context).width < kCompactMax;

bool isMedium(BuildContext context) {
  final w = MediaQuery.sizeOf(context).width;
  return w >= kCompactMax && w < kMediumMax;
}

bool isExpanded(BuildContext context) {
  final w = MediaQuery.sizeOf(context).width;
  return w >= kMediumMax && w < kExpandedMax;
}

bool isLarge(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= kExpandedMax;

/// The primary switch: wide layouts (side rail, split view, centered dialogs).
bool isWide(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= kMediumMax;
