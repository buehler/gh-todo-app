import 'package:flutter_test/flutter_test.dart';
import 'package:gh_todos/util/markdown_tasks.dart';

void main() {
  test('toggles only the selected task marker across supported list forms', () {
    const markdown = '''
- [ ] First
1. [X] Second
  * [ ] Third
> - [x] Fourth
''';

    expect(
      toggleMarkdownTaskAtIndex(markdown, taskIndex: 1, checked: false),
      '''
- [ ] First
1. [ ] Second
  * [ ] Third
> - [x] Fourth
''',
    );
    expect(
      toggleMarkdownTaskAtIndex(markdown, taskIndex: 2, checked: true),
      '''
- [ ] First
1. [X] Second
  * [x] Third
> - [x] Fourth
''',
    );
  });

  test('uses source order when task labels are duplicated', () {
    const markdown = '- [ ] Repeat\n- [ ] Repeat';

    expect(
      toggleMarkdownTaskAtIndex(markdown, taskIndex: 1, checked: true),
      '- [ ] Repeat\n- [x] Repeat',
    );
  });

  test('ignores task-like text inside fenced code blocks', () {
    const markdown = '''
```md
- [ ] Not a task
```
- [ ] Actual task
''';

    expect(
      toggleMarkdownTaskAtIndex(markdown, taskIndex: 0, checked: true),
      '''
```md
- [ ] Not a task
```
- [x] Actual task
''',
    );
  });

  test('returns null when the rendered task cannot be mapped', () {
    expect(
      toggleMarkdownTaskAtIndex('- [ ] Only task', taskIndex: 1, checked: true),
      isNull,
    );
  });
}
