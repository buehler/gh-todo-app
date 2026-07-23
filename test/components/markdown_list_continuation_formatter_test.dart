import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gh_todos/components/components.dart';

void main() {
  const formatter = MarkdownListContinuationFormatter();

  TextEditingValue value(String text, {int? caret}) {
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: caret ?? text.length),
    );
  }

  TextEditingValue enter(TextEditingValue before) {
    final caret = before.selection.extentOffset;
    return before.copyWith(
      text: before.text.replaceRange(caret, caret, '\n'),
      selection: TextSelection.collapsed(offset: caret + 1),
      composing: TextRange.empty,
    );
  }

  test('continues unordered list markers and preserves indentation', () {
    for (final testCase in [
      ('- first', '- first\n- '),
      ('* first', '* first\n* '),
      ('+ first', '+ first\n+ '),
      ('  - nested', '  - nested\n  - '),
    ]) {
      final result = formatter.formatEditUpdate(
        value(testCase.$1),
        enter(value(testCase.$1)),
      );

      expect(result.text, testCase.$2);
      expect(result.selection.baseOffset, testCase.$2.length);
    }
  });

  test('increments ordered Markdown list markers', () {
    for (final testCase in [
      ('1. first', '1. first\n2. '),
      ('9) ninth', '9) ninth\n10) '),
    ]) {
      final result = formatter.formatEditUpdate(
        value(testCase.$1),
        enter(value(testCase.$1)),
      );

      expect(result.text, testCase.$2);
      expect(result.selection.baseOffset, testCase.$2.length);
    }
  });

  test('continues unchecked task lists as unchecked items', () {
    final result = formatter.formatEditUpdate(
      value('- [ ] first task'),
      enter(value('- [ ] first task')),
    );

    expect(result.text, '- [ ] first task\n- [ ] ');
    expect(result.selection.baseOffset, '- [ ] first task\n- [ ] '.length);
  });

  test('continues checked task lists as unchecked items', () {
    final result = formatter.formatEditUpdate(
      value('* [x] completed task'),
      enter(value('* [x] completed task')),
    );

    expect(result.text, '* [x] completed task\n* [ ] ');
    expect(result.selection.baseOffset, '* [x] completed task\n* [ ] '.length);
  });

  test('exits a marker-only list item without adding a blank line', () {
    const before = '- first\n- ';
    final result = formatter.formatEditUpdate(
      value(before),
      enter(value(before)),
    );

    expect(result.text, '- first\n');
    expect(result.selection.baseOffset, '- first\n'.length);
  });

  test('leaves plain text and manually removed list markers unchanged', () {
    for (final before in ['', 'plain text', '- first\nplain text']) {
      final result = formatter.formatEditUpdate(
        value(before),
        enter(value(before)),
      );

      expect(result.text, '$before\n');
      expect(result.selection.baseOffset, '$before\n'.length);
    }
  });

  test('leaves multi-character pasted content unchanged', () {
    const pastedText = '- first\nplain text';
    final result = formatter.formatEditUpdate(value(''), value(pastedText));

    expect(result, value(pastedText));
  });

  test('continues list markers inserted between existing list items', () {
    for (final testCase in [
      ('- first\n- second', '- first\n- \n- second'),
      ('+ [x] first\n+ [ ] second', '+ [x] first\n+ [ ] \n+ [ ] second'),
      ('4. first\n5. second', '4. first\n5. \n5. second'),
    ]) {
      final newlineOffset = testCase.$1.indexOf('\n');
      final oldValue = value(testCase.$1, caret: newlineOffset);
      final result = formatter.formatEditUpdate(oldValue, enter(oldValue));

      expect(result.text, testCase.$2);
      expect(
        result.selection.baseOffset,
        testCase.$2.indexOf('\n', newlineOffset + 1),
      );
    }
  });

  test('continues a newly completed item between existing list items', () {
    const before = '- first\n- third';
    final firstNewlineOffset = before.indexOf('\n');
    final initialValue = value(before, caret: firstNewlineOffset);
    final completed = formatter.formatEditUpdate(
      initialValue,
      enter(initialValue),
    );
    final typed = completed.copyWith(
      text: completed.text.replaceRange(
        completed.selection.extentOffset,
        completed.selection.extentOffset,
        'second',
      ),
      selection: TextSelection.collapsed(
        offset: completed.selection.extentOffset + 'second'.length,
      ),
    );
    final result = formatter.formatEditUpdate(typed, enter(typed));

    expect(result.text, '- first\n- second\n- \n- third');
    expect(result.selection.baseOffset, '- first\n- second\n- '.length);
  });

  test('leaves newline edits with a non-collapsed selection unchanged', () {
    const text = '- first\n';
    final result = formatter.formatEditUpdate(
      value('- first'),
      TextEditingValue(
        text: text,
        selection: const TextSelection(
          baseOffset: 0,
          extentOffset: text.length,
        ),
      ),
    );

    expect(result.text, text);
    expect(
      result.selection,
      const TextSelection(baseOffset: 0, extentOffset: text.length),
    );
  });
}
