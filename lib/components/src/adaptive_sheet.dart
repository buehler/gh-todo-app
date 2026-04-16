import 'package:flutter/material.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/style/breakpoints.dart';
import 'package:gh_todos/style/colors.dart';

/// Signature for adaptive sheet builders. Receives [isDialog] so the content
/// widget can skip its drag-handle / DraggableScrollableSheet wrapper when
/// rendered as a centered desktop dialog.
typedef AdaptiveSheetBuilder = Widget Function(
  BuildContext context,
  bool isDialog,
);

/// Opens a modal that adapts to the current breakpoint:
///
/// - On compact/medium widths (`< 900`), shows a modal bottom sheet —
///   identical to `showModalBottomSheet` with the app's transparent-background
///   convention.
/// - On wide widths (`≥ 900`), shows a centered dialog with a
///   [dialogMaxWidth]-capped editorial surface card, matching DESIGN.md's
///   tonal-layering + editorial-radius language (no 1px borders).
///
/// The [builder] receives `isDialog` so it can tailor chrome:
/// - Skip the drag handle when rendered as a dialog.
/// - Swap `DraggableScrollableSheet` for a plain `SingleChildScrollView`.
/// - Skip the own rounded-container wrapper (the adapter provides it).
Future<T?> showAdaptiveSheet<T>(
  BuildContext context, {
  required AdaptiveSheetBuilder builder,
  double dialogMaxWidth = 560,
  bool useRootNavigator = true,
  bool isScrollControlled = true,
}) {
  if (isWide(context)) {
    return showDialog<T>(
      context: context,
      useRootNavigator: useRootNavigator,
      barrierColor: Colors.black.withAlpha((255 * 0.32).round()),
      barrierDismissible: true,
      builder: (c) {
        final surfaceLowest = resolveColor(
          c,
          ColorTokens.surface.containerLowest,
        );
        final screenHeight = MediaQuery.sizeOf(c).height;
        final keyboardInset = MediaQuery.viewInsetsOf(c).bottom;

        return Padding(
          padding: EdgeInsets.only(bottom: keyboardInset),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: dialogMaxWidth,
                maxHeight: screenHeight * 0.88,
              ),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    color: surfaceLowest,
                    borderRadius: BorderRadius.circular(editorialRadiusLarge),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha((255 * 0.14).round()),
                        blurRadius: 48,
                        spreadRadius: 0,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: builder(c, true),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useRootNavigator: useRootNavigator,
    backgroundColor: Colors.transparent,
    builder: (c) => builder(c, false),
  );
}

/// Shared drag handle used at the top of bottom-sheet-mode sheets. Returns an
/// empty widget when [isDialog] is true — the dialog has no affordance to
/// drag, so the handle would only clutter the chrome.
class AdaptiveSheetDragHandle extends StatelessWidget {
  final bool isDialog;

  const AdaptiveSheetDragHandle({required this.isDialog, super.key});

  @override
  Widget build(BuildContext context) {
    if (isDialog) return const SizedBox.shrink();

    final outlineVariant = resolveColor(context, ColorTokens.outline.variant);
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: withOpacity(outlineVariant, 0.3),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
