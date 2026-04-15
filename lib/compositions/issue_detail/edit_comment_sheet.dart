import 'package:flutter/material.dart';
import 'package:gh_todos/components/components.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/models/issue_details.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:gh_todos/style/typography.dart';
import 'package:mix/mix.dart';

/// Opens an "Edit Comment" bottom sheet pre-populated with [comment]'s body.
/// Returns the updated body on save, or `null` if dismissed / unchanged.
Future<String?> showEditCommentSheet(
  BuildContext context, {
  required IssueComment comment,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _EditCommentSheet(comment: comment),
  );
}

class _EditCommentSheet extends StatefulWidget {
  final IssueComment comment;

  const _EditCommentSheet({required this.comment});

  @override
  State<_EditCommentSheet> createState() => _EditCommentSheetState();
}

class _EditCommentSheetState extends State<_EditCommentSheet> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.comment.body,
  );

  String get _text => _controller.text;

  bool get _isValid => _text.trim().isNotEmpty;

  bool get _isDirty => _text != widget.comment.body;

  bool get _canSave => _isValid && _isDirty;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String _) {
    // Rebuild so Save's enabled state reflects the current draft.
    setState(() {});
  }

  void _save() {
    Navigator.pop(context, _controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final surfaceLowest = resolveColor(
      context,
      ColorTokens.surface.containerLowest,
    );
    final onSurface = resolveColor(context, ColorTokens.surface.on);
    final outlineVariant = resolveColor(context, ColorTokens.outline.variant);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: BoxDecoration(
          color: surfaceLowest,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: withOpacity(outlineVariant, 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: StyledText(
                'Edit Comment',
                style: editorialTextStyle(
                  TextTokens.title.$large,
                  color: onSurface,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: EditorialTextField(
                controller: _controller,
                hintText: 'Update the comment…',
                onChanged: _onChanged,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                minLines: 4,
                maxLines: 10,
                autofocus: true,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Row(
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
                    child: EditorialButton(
                      label: 'Save',
                      enabled: _canSave,
                      onPressed: _canSave ? _save : null,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: MediaQuery.paddingOf(context).bottom + 16),
          ],
        ),
      ),
    );
  }
}
