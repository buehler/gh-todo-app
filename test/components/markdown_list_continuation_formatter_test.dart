import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gh_todos/components/components.dart';

void main() {
  const formatter = MarkdownListContinuationFormatter();

  TextEditingValue value(String text) {
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  TextEditingValue enter(String before) {
    return value('$before\n');
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
        enter(testCase.$1),
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
        enter(testCase.$1),
      );

      expect(result.text, testCase.$2);
      expect(result.selection.baseOffset, testCase.$2.length);
    }
  });

  test('continues unchecked task lists as unchecked items', () {
    final result = formatter.formatEditUpdate(
      value('- [ ] first task'),
      enter('- [ ] first task'),
    );

    expect(result.text, '- [ ] first task\n- [ ] ');
    expect(result.selection.baseOffset, '- [ ] first task\n- [ ] '.length);
  });

  test('continues checked task lists as unchecked items', () {
    final result = formatter.formatEditUpdate(
      value('* [x] completed task'),
      enter('* [x] completed task'),
    );

    expect(result.text, '* [x] completed task\n* [ ] ');
    expect(result.selection.baseOffset, '* [x] completed task\n* [ ] '.length);
  });

  test('exits a marker-only list item without adding a blank line', () {
    const before = '- first\n- ';
    final result = formatter.formatEditUpdate(value(before), enter(before));

    expect(result.text, '- first\n');
    expect(result.selection.baseOffset, '- first\n'.length);
  });

  test('leaves plain text and manually removed list markers unchanged', () {
    for (final before in ['', 'plain text', '- first\nplain text']) {
      final result = formatter.formatEditUpdate(value(before), enter(before));

      expect(result.text, '$before\n');
      expect(result.selection.baseOffset, '$before\n'.length);
    }
  });

  test('leaves multi-character pasted content unchanged', () {
    const pastedText = '- first\nplain text';
    final result = formatter.formatEditUpdate(value(''), value(pastedText));

    expect(result, value(pastedText));
  });
}
