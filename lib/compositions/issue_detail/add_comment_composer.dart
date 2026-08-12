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
/// [onSubmit] returns `true` on success (composer clears) and `false` on
/// failure (composer keeps the draft so the user can retry). While the host
/// handler is awaiting a network round-trip, the submit button disables
/// itself — no need for the caller to pass an `enabled` flag.
class AddCommentComposer extends StatefulWidget {
  static const pageKey = ValueKey('add-comment-composer');
  static const fieldKey = ValueKey('add-comment-composer-field');
  static const submitKey = ValueKey('add-comment-composer-submit');

  final Future<bool> Function(String body)? onSubmit;
  final bool enabled;

  const AddCommentComposer({this.onSubmit, this.enabled = true, super.key});

  @override
  State<AddCommentComposer> createState() => _AddCommentComposerState();
}

class _AddCommentComposerState extends State<AddCommentComposer> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _submitting = false;

  bool get _hasText => _controller.text.trim().isNotEmpty;

  bool get _canSubmit => _hasText && !_submitting;

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String _) {
    // Rebuild so the submit button's enabled/disabled state reflects the
    // current text without us needing a dedicated value listener.
    setState(() {});
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final handler = widget.onSubmit;
    if (handler == null || !widget.enabled) return;

    setState(() => _submitting = true);
    try {
      final ok = await handler(text);
      if (!mounted) return;
      if (ok) {
        _controller.clear();
        _focusNode.unfocus();
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
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
          focusNode: _focusNode,
          hintText: 'Add a comment…',
          onChanged: _onChanged,
          onSubmitted: (_) => _submit(),
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          inputFormatters: const [MarkdownListContinuationFormatter()],
          enabled: widget.enabled && !_submitting,
          submitOnModifierEnter: true,
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
            enabled: widget.enabled && _canSubmit,
            loading: _submitting,
            onPressed: widget.enabled && _canSubmit ? _submit : null,
          ),
        ),
      ],
    );
  }
}
