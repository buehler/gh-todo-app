import 'package:flutter/material.dart';
import 'package:gh_todos/components/components.dart';
import 'package:gh_todos/components/src/adaptive_sheet.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/providers/issue_mutations.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:gh_todos/style/typography.dart';
import 'package:mix/mix.dart';

Future<CommentHideReason?> showHideCommentSheet(BuildContext context) {
  return showAdaptiveSheet<CommentHideReason>(
    context,
    builder: (_, isDialog) => _HideCommentSheet(isDialog: isDialog),
  );
}

Future<bool> showDeleteCommentSheet(BuildContext context) async {
  return await showAdaptiveSheet<bool>(
        context,
        builder: (_, isDialog) => _DeleteCommentSheet(isDialog: isDialog),
      ) ??
      false;
}

class _HideCommentSheet extends StatefulWidget {
  final bool isDialog;
  const _HideCommentSheet({required this.isDialog});

  @override
  State<_HideCommentSheet> createState() => _HideCommentSheetState();
}

class _HideCommentSheetState extends State<_HideCommentSheet> {
  CommentHideReason _reason = CommentHideReason.outdated;

  @override
  Widget build(BuildContext context) {
    return _SheetSurface(
      isDialog: widget.isDialog,
      title: 'Hide comment',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StyledText(
            'Reason',
            style: editorialTextStyle(
              TextTokens.label.$medium,
              color: resolveColor(context, ColorTokens.surface.onVariant),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<CommentHideReason>(
            key: const ValueKey('hide-comment-reason'),
            initialValue: _reason,
            isExpanded: true,
            decoration: InputDecoration(
              filled: true,
              fillColor: resolveColor(
                context,
                ColorTokens.surface.containerHigh,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
            ),
            borderRadius: BorderRadius.circular(editorialRadiusMedium),
            items: CommentHideReason.values
                .map(
                  (reason) => DropdownMenuItem(
                    value: reason,
                    child: Text(reason.label),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _reason = value!),
          ),
          const SizedBox(height: 16),
          StyledText(
            'The comment will remain in the conversation and can be shown again.',
            style: editorialTextStyle(
              TextTokens.body.$medium,
              color: resolveColor(context, ColorTokens.surface.onVariant),
            ),
          ),
          const SizedBox(height: 24),
          _SheetActions(
            primaryLabel: 'Hide comment',
            onPrimary: () => Navigator.pop(context, _reason),
          ),
        ],
      ),
    );
  }
}

class _DeleteCommentSheet extends StatelessWidget {
  final bool isDialog;
  const _DeleteCommentSheet({required this.isDialog});

  @override
  Widget build(BuildContext context) {
    final error = resolveColor(context, ColorTokens.error.$default);
    return _SheetSurface(
      isDialog: isDialog,
      title: 'Delete comment?',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StyledText(
            'This permanently deletes the comment from the issue.',
            style: editorialTextStyle(
              TextTokens.body.$medium,
              color: resolveColor(context, ColorTokens.surface.onVariant),
            ),
          ),
          const SizedBox(height: 24),
          _SheetActions(
            primaryLabel: 'Delete comment',
            primaryColor: error,
            onPrimary: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
  }
}

class _SheetSurface extends StatelessWidget {
  final bool isDialog;
  final String title;
  final Widget child;
  const _SheetSurface({
    required this.isDialog,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdaptiveSheetDragHandle(isDialog: isDialog),
          if (isDialog) const SizedBox(height: 24),
          StyledText(
            title,
            style: editorialTextStyle(
              TextTokens.title.$large,
              color: resolveColor(context, ColorTokens.surface.on),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
    if (isDialog) return content;
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
      decoration: BoxDecoration(
        color: resolveColor(context, ColorTokens.surface.containerLowest),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: content,
    );
  }
}

class _SheetActions extends StatelessWidget {
  final String primaryLabel;
  final Color? primaryColor;
  final VoidCallback onPrimary;
  const _SheetActions({
    required this.primaryLabel,
    this.primaryColor,
    required this.onPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final primary = primaryColor;
    return Row(
      children: [
        Expanded(
          child: EditorialButton(
            label: 'Cancel',
            variation: ButtonVariation.secondary,
            onPressed: () => Navigator.pop(context),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: primary == null
              ? EditorialButton(label: primaryLabel, onPressed: onPrimary)
              : PressableBox(
                  onPress: onPrimary,
                  style: BoxStyler()
                      .minHeight(48)
                      .borderRounded(editorialRadiusMedium)
                      .color(primary)
                      .alignment(Alignment.center),
                  child: StyledText(
                    primaryLabel,
                    style: editorialTextStyle(
                      TextTokens.title.$small,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

extension CommentHideReasonLabel on CommentHideReason {
  String get label => switch (this) {
    CommentHideReason.abuse => 'Abuse',
    CommentHideReason.duplicate => 'Duplicate',
    CommentHideReason.offTopic => 'Off-topic',
    CommentHideReason.outdated => 'Outdated',
    CommentHideReason.resolved => 'Resolved',
    CommentHideReason.spam => 'Spam',
  };
}
