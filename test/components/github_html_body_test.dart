import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gh_todos/components/github_html_body.dart';
import 'package:gh_todos/style/themes.dart';

void main() {
  Widget harness(String? html, {String? emptyText}) {
    return octanePrime(
      MaterialApp(
        home: Scaffold(
          body: GithubHtmlBody(html: html, emptyText: emptyText),
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

  testWidgets('does not crash on malformed html', (tester) async {
    await tester.pumpWidget(harness('<p>Open <strong>tags'));

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Open'), findsOneWidget);
  });
}
