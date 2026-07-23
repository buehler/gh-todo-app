import 'dart:async';
import 'dart:ui' show CheckedState;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gh_todos/components/github_html_body.dart';
import 'package:gh_todos/style/themes.dart';

void main() {
  Widget harness(
    String? html, {
    String? emptyText,
    Future<void> Function(int taskIndex, bool checked)? onTaskToggle,
    bool taskToggleBusy = false,
  }) {
    return octanePrime(
      MaterialApp(
        home: Scaffold(
          body: GithubHtmlBody(
            html: html,
            emptyText: emptyText,
            onTaskToggle: onTaskToggle,
            taskToggleBusy: taskToggleBusy,
          ),
        ),
      ),
    );
  }

  testWidgets('renders common GitHub markdown HTML blocks', (tester) async {
    await tester.pumpWidget(
      harness('''
<h1>Heading</h1>
<p>Paragraph with <a href="https://github.com">link</a> and <code>code</code>.</p>
<ul><li>First item</li><li>Second item</li></ul>
<blockquote><p>Quoted text</p></blockquote>
<pre><code>final value = 1;</code></pre>
<table><thead><tr><th>Name</th></tr></thead><tbody><tr><td>Octane</td></tr></tbody></table>
'''),
    );

    expect(find.text('Heading'), findsOneWidget);
    expect(find.textContaining('Paragraph with'), findsOneWidget);
    expect(find.text('First item'), findsOneWidget);
    expect(find.text('Second item'), findsOneWidget);
    expect(find.text('Quoted text'), findsOneWidget);
    expect(find.textContaining('final value = 1;'), findsOneWidget);
    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Octane'), findsOneWidget);
  });

  testWidgets('renders empty state text when html is empty', (tester) async {
    await tester.pumpWidget(harness('', emptyText: 'No description provided.'));

    expect(find.text('No description provided.'), findsOneWidget);
  });

  testWidgets('renders task-list semantics and sends source-order toggles', (
    tester,
  ) async {
    final toggles = <(int, bool)>[];
    await tester.pumpWidget(
      harness(
        '''
<ul class="contains-task-list">
  <li class="task-list-item"><input type="checkbox" disabled>Open task</li>
  <li class="task-list-item"><input type="checkbox" checked disabled>Done task</li>
</ul>
<p><input type="checkbox">Raw HTML input</p>
''',
        onTaskToggle: (taskIndex, checked) async {
          toggles.add((taskIndex, checked));
        },
      ),
    );

    final first = find.byKey(const ValueKey('github-task-checkbox-0'));
    final second = find.byKey(const ValueKey('github-task-checkbox-1'));
    expect(first, findsOneWidget);
    expect(second, findsOneWidget);
    expect(
      tester.getSemantics(first).flagsCollection.isChecked,
      CheckedState.isFalse,
    );
    expect(
      tester.getSemantics(second).flagsCollection.isChecked,
      CheckedState.isTrue,
    );
    expect(find.byKey(const ValueKey('github-task-checkbox-2')), findsNothing);

    await tester.tap(first);
    await tester.tap(second);
    await tester.pump();

    expect(toggles, [(0, true), (1, false)]);
    expect(find.textContaining('Open task'), findsOneWidget);
    expect(find.textContaining('Done task'), findsOneWidget);
  });

  testWidgets('keeps task checkbox label spacing consistent', (tester) async {
    await tester.pumpWidget(
      harness('''
<ul class="contains-task-list">
  <li class="task-list-item"><input type="checkbox">   First task</li>
  <li class="task-list-item"><input type="checkbox">Second task</li>
  <li class="task-list-item"><input type="checkbox"> Third task</li>
</ul>
<ul><li>Normal item</li></ul>
'''),
    );

    final firstCheckbox = find.byKey(const ValueKey('github-task-checkbox-0'));
    final secondCheckbox = find.byKey(const ValueKey('github-task-checkbox-1'));
    final thirdCheckbox = find.byKey(const ValueKey('github-task-checkbox-2'));

    final firstGap =
        tester.getTopLeft(find.textContaining('First task')).dx -
        tester.getTopRight(firstCheckbox).dx;
    final secondGap =
        tester.getTopLeft(find.textContaining('Second task')).dx -
        tester.getTopRight(secondCheckbox).dx;
    final thirdGap =
        tester.getTopLeft(find.textContaining('Third task')).dx -
        tester.getTopRight(thirdCheckbox).dx;

    expect(firstGap, closeTo(secondGap, 0.01));
    expect(firstGap, closeTo(thirdGap, 0.01));
    expect(find.byKey(const ValueKey('github-task-checkbox-3')), findsNothing);
    expect(find.text('Normal item'), findsOneWidget);
  });

  testWidgets('does not send a duplicate task toggle while one is in flight', (
    tester,
  ) async {
    final completer = Completer<void>();
    var callCount = 0;
    await tester.pumpWidget(
      harness(
        '''
<ul class="contains-task-list">
  <li class="task-list-item"><input type="checkbox">Open task</li>
</ul>
''',
        onTaskToggle: (_, _) {
          callCount++;
          return completer.future;
        },
      ),
    );

    final checkbox = find.byKey(const ValueKey('github-task-checkbox-0'));
    await tester.tap(checkbox);
    await tester.pump();
    await tester.tap(checkbox);
    await tester.pump();

    expect(callCount, 1);
    completer.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('does not crash on malformed html', (tester) async {
    await tester.pumpWidget(harness('<p>Open <strong>tags'));

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Open'), findsOneWidget);
  });
}
