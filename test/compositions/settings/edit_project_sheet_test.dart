import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gh_todos/components/editorial_button.dart';
import 'package:gh_todos/compositions/settings/edit_project_sheet.dart';
import 'package:gh_todos/models/project.dart';
import 'package:gh_todos/style/themes.dart';

void main() {
  testWidgets('edits and trims a project issue query', (tester) async {
    await tester.binding.setSurfaceSize(const Size(700, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    EditProjectResult? result;
    const project = Project(id: 'project-1', name: 'Inbox');

    await tester.pumpWidget(
      ProviderScope(
        child: octanePrime(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      result = await showEditProjectSheet(context, project);
                    },
                    child: const Text('Edit project'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Edit project'));
    await tester.pumpAndSettle();

    expect(find.text('ISSUE QUERY'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
    final saveButton = find.ancestor(
      of: find.text('Save'),
      matching: find.byType(EditorialButton),
    );
    expect(tester.widget<EditorialButton>(saveButton).enabled, isFalse);

    await tester.enterText(find.byType(TextField).first, '  no:assignee  ');
    await tester.pump();

    expect(tester.widget<EditorialButton>(saveButton).enabled, isTrue);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(result, isA<UpdateProjectResult>());
    expect((result! as UpdateProjectResult).project.issueQuery, 'no:assignee');
  });
}
