import 'package:flutter/material.dart';
import 'package:gh_todos/components/components.dart';
import 'package:gh_todos/components/src/component_foundation.dart';

/// Composer anchored at the bottom of the conversation transcript.
///
/// Tonal-layering per DESIGN.md: the field's minimalist [EditorialTextField]
/// sits directly on the page `surface` (no wrapping card, no dividers — the
/// surface shift between the field's `surface_container_low` fill and the
/// surrounding canvas defines the boundary). The "Post Comment" CTA uses the
/// secondary button variation (flat `surface_container_high` fill) rather than
/// the gradient primary — posting a comment is ancillary to the page's real
/// primary action ("Close/Re-open Issue" above), so it reads as a quiet
/// finishing affordance instead of competing with it.
///
/// Save is intentionally a no-op for now — wiring the GitHub mutation is a
/// follow-up, matching the state-action and edit-issue stubs elsewhere on the
/// page.
class AddCommentComposer extends StatefulWidget {
  static const pageKey = ValueKey('add-comment-composer');
  static const fieldKey = ValueKey('add-comment-composer-field');
  static const submitKey = ValueKey('add-comment-composer-submit');

  final ValueChanged<String>? onSubmit;

  const AddCommentComposer({this.onSubmit, super.key});

  @override
  State<AddCommentComposer> createState() => _AddCommentComposerState();
}

class _AddCommentComposerState extends State<AddCommentComposer> {
  final TextEditingController _controller = TextEditingController();

  bool get _hasText => _controller.text.trim().isNotEmpty;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String _) {
    // Rebuild so the submit button's enabled/disabled state reflects the
    // current text without us needing a dedicated value listener.
    setState(() {});
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSubmit?.call(text);
    // Clear optimistically so the field returns to its resting state. Once the
    // save mutation is wired up this will move to the success callback.
    _controller.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      key: AddCommentComposer.pageKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EditorialTextField(
          key: AddCommentComposer.fieldKey,
          controller: _controller,
          hintText: 'Add a comment…',
          onChanged: _onChanged,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          minLines: 3,
          maxLines: 6,
        ),
        const SizedBox(height: editorialRadiusMedium),
        Align(
          alignment: Alignment.centerRight,
          child: EditorialButton(
            key: AddCommentComposer.submitKey,
            label: 'Post Comment',
            variation: ButtonVariation.secondary,
            enabled: _hasText,
            onPressed: _hasText ? _submit : null,
          ),
        ),
      ],
    );
  }
}
