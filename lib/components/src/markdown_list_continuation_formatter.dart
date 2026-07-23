import 'package:flutter/services.dart';

/// Continues Markdown list items when the user inserts a single newline.
///
/// This formatter intentionally only transforms a one-character newline
/// insertion. Other edits, including multi-character pastes, pass through
/// unchanged.
class MarkdownListContinuationFormatter extends TextInputFormatter {
  const MarkdownListContinuationFormatter();

  static final RegExp _unorderedPrefix = RegExp(
    r'^([ \t]*)([-+*])([ \t]+)(?:\[[ xX]\]([ \t]*))?',
  );
  static final RegExp _orderedPrefix = RegExp(r'^([ \t]*)(\d+)([.)])([ \t]+)');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final insertionOffset = _singleNewlineInsertionOffset(oldValue, newValue);
    if (insertionOffset == null) return newValue;

    final lineStart = insertionOffset == 0
        ? 0
        : newValue.text.lastIndexOf('\n', insertionOffset - 1) + 1;
    final line = newValue.text.substring(lineStart, insertionOffset);
    final continuation = _continuationFor(line);
    if (continuation == null) return newValue;

    if (continuation.isEmpty) {
      // Pressing Enter on an empty list item exits the list. Remove both the
      // marker-only line and the newly inserted newline, leaving its existing
      // line break as a normal, empty paragraph.
      return _withTextAndCaret(
        newValue,
        newValue.text.replaceRange(lineStart, insertionOffset + 1, ''),
        lineStart,
      );
    }

    final text = newValue.text.replaceRange(
      insertionOffset,
      insertionOffset + 1,
      '\n$continuation',
    );
    return _withTextAndCaret(
      newValue,
      text,
      insertionOffset + 1 + continuation.length,
    );
  }

  int? _singleNewlineInsertionOffset(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final oldText = oldValue.text;
    final newText = newValue.text;
    final selection = newValue.selection;
    if (!selection.isValid || !selection.isCollapsed) return null;
    if (newText.length != oldText.length + 1) return null;

    // The platform places the collapsed caret immediately after a typed
    // newline. Unlike a text diff, this remains unambiguous when Enter is
    // pressed adjacent to an existing newline between two list items.
    final insertionOffset = selection.extentOffset - 1;
    if (insertionOffset < 0 || insertionOffset >= newText.length) {
      return null;
    }
    if (newText.codeUnitAt(insertionOffset) != '\n'.codeUnitAt(0)) {
      return null;
    }

    final restoredText = newText.replaceRange(
      insertionOffset,
      insertionOffset + 1,
      '',
    );
    return restoredText == oldText ? insertionOffset : null;
  }

  String? _continuationFor(String line) {
    final unordered = _unorderedPrefix.firstMatch(line);
    if (unordered != null) {
      final content = line.substring(unordered.end);
      if (content.trim().isEmpty) return '';

      final indentation = unordered.group(1)!;
      final marker = unordered.group(2)!;
      final markerSpacing = unordered.group(3)!;
      final taskSpacing = unordered.group(4);
      if (taskSpacing != null) {
        return '$indentation$marker$markerSpacing[ ] ';
      }
      return '$indentation$marker$markerSpacing';
    }

    final ordered = _orderedPrefix.firstMatch(line);
    if (ordered == null) return null;

    final content = line.substring(ordered.end);
    if (content.trim().isEmpty) return '';

    final number = int.tryParse(ordered.group(2)!);
    if (number == null) return null;
    return '${ordered.group(1)!}${number + 1}${ordered.group(3)!}${ordered.group(4)!}';
  }

  TextEditingValue _withTextAndCaret(
    TextEditingValue textValue,
    String text,
    int caret,
  ) {
    return textValue.copyWith(
      text: text,
      selection: TextSelection.collapsed(offset: caret),
      composing: TextRange.empty,
    );
  }
}
