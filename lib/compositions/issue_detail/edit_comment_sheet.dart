import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gh_todos/components/components.dart';
import 'package:gh_todos/components/src/adaptive_sheet.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/models/issue_details.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:gh_todos/style/typography.dart';
import 'package:mix/mix.dart';

/// Opens an "Edit Comment" sheet pre-populated with [comment]'s body. Adapts
/// to a centered dialog on wide screens. Returns the updated body on save,
/// or `null` if dismissed / unchanged.
Future<String?> showEditCommentSheet(
  BuildContext context, {
  required IssueComment comment,
}) {
  return showAdaptiveSheet<String>(
    context,
    builder: (_, isDialog) =>
        _EditCommentSheet(comment: comment, isDialog: isDialog),
  );
}

class _EditCommentSheet extends StatefulWidget {
  final IssueComment comment;
  final bool isDialog;

  const _EditCommentSheet({required this.comment, required this.isDialog});

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

  void _saveIfPossible() {
    if (_canSave) _save();
  }

  @override
  Widget build(BuildContext context) {
    final surfaceLowest = resolveColor(
      context,
      ColorTokens.surface.containerLowest,
    );
    final onSurface = resolveColor(context, ColorTokens.surface.on);

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdaptiveSheetDragHandle(isDialog: widget.isDialog),
        Padding(
          padding: EdgeInsets.fromLTRB(24, widget.isDialog ? 24 : 0, 24, 16),
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
            inputFormatters: const [MarkdownListContinuationFormatter()],
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
        if (!widget.isDialog)
          SizedBox(height: MediaQuery.paddingOf(context).bottom + 16),
      ],
    );

    final sheet = widget.isDialog
        // Adapter provides the rounded surface + shadow. We only supply content.
        ? content
        : Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: surfaceLowest,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: content,
            ),
          );

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter, control: true):
            _saveIfPossible,
        const SingleActivator(LogicalKeyboardKey.enter, meta: true):
            _saveIfPossible,
      },
      child: sheet,
    );
  }
}
