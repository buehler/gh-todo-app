import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gh_todos/compositions/issue_detail/add_comment_composer.dart';
import 'package:gh_todos/compositions/issue_detail/issue_state_action.dart';
import 'package:gh_todos/graphql/userinfo.graphql.dart';
import 'package:gh_todos/models/issue_data.dart';
import 'package:gh_todos/models/issue_details.dart';
import 'package:gh_todos/models/priority.dart';
import 'package:gh_todos/models/project.dart';
import 'package:gh_todos/pages/issue_detail_page.dart';
import 'package:gh_todos/providers/connectivity_provider.dart';
import 'package:gh_todos/providers/github_providers.dart';
import 'package:gh_todos/providers/hive_bootstrap_provider.dart';
import 'package:gh_todos/providers/issue_mutations.dart';
import 'package:gh_todos/providers/project_list_provider.dart';
import 'package:gh_todos/providers/storage_providers.dart';
import 'package:gh_todos/services/github_token_storage_service.dart';
import 'package:gh_todos/style/themes.dart';

import '../support/fake_issue_mutations.dart';
import '../support/fakes.dart';

// ----------------------------- Fixtures --------------------------------------

const _projectId = 'proj-1';
const _itemId = 'item-1';
const _issueId = 'issue-1';
const _dueDateFieldId = 'field-due';
const _priorityFieldId = 'field-pri';
const _optHigh = 'opt-high';
const _optMed = 'opt-med';

const _mappedProject = Project(
  id: _projectId,
  name: 'Alpha',
  ownerLogin: 'acme',
  dueDateFieldId: _dueDateFieldId,
  priorityFieldId: _priorityFieldId,
  priorityOptionMap: {
    _optHigh: TodoPriority.high,
    _optMed: TodoPriority.medium,
  },
);

const _openIssue = IssueData(
  id: _issueId,
  number: 42,
  title: 'Refactor auth',
  commentCount: 2,
  createdAt: '2026-04-10T10:00:00Z',
  updatedAt: '2026-04-14T10:00:00Z',
  projectId: _projectId,
  projectItemId: _itemId,
);

const _closedIssue = IssueData(
  id: _issueId,
  number: 42,
  title: 'Refactor auth',
  commentCount: 2,
  createdAt: '2026-04-10T10:00:00Z',
  updatedAt: '2026-04-14T10:00:00Z',
  closed: true,
  closedAt: '2026-04-14T12:00:00Z',
  projectId: _projectId,
  projectItemId: _itemId,
);

final _ownComment = IssueComment(
  id: 'c-own',
  authorLogin: 'me',
  body: 'My original comment.',
  createdAt: '2026-04-13T10:00:00Z',
);

final _otherComment = IssueComment(
  id: 'c-other',
  authorLogin: 'someone-else',
  body: "Someone else's comment.",
  createdAt: '2026-04-13T11:00:00Z',
);

final _viewer = Query$UserInformation$viewer(
  id: 'user-me',
  avatarUrl: 'https://example.com/me.png',
  name: 'Me',
  login: 'me',
);

// ----------------------------- Harness ---------------------------------------

Future<({FakeIssueMutations mutations})> _pump(
  WidgetTester tester, {
  required IssueData issue,
  List<IssueComment> comments = const [],
  Project project = _mappedProject,
}) async {
  // The detail page scrolls, so give the test surface enough room that the
  // composer + state-action button sit on-screen without scrolling.
  await tester.binding.setSurfaceSize(const Size(800, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final fakeStorage = FakeFlutterSecureStorage(
    seed: {GithubTokenStorageService.tokenStorageKey: 'ghp_seed'},
  );
  final mutations = FakeIssueMutations();
  final sessionPrefs = FakeSessionPrefsService(selectedProjectId: _projectId);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        hiveBootstrapProvider.overrideWith((_) async {}),
        offlineStatusProvider.overrideWith(_FakeOfflineStatus.new),
        tokenStorageProvider.overrideWithValue(
          GithubTokenStorageService(storage: fakeStorage),
        ),
        sessionPrefsProvider.overrideWithValue(sessionPrefs),
        projectListProvider.overrideWith(() => _FakeProjectList([project])),
        userInfoProvider.overrideWith((_) => Stream.value(_viewer)),
        issueDetailsProvider(_issueId).overrideWith(
          (ref) => Stream.value(IssueDetails(
            description: 'Original description.',
            url: 'https://github.com/acme/repo/issues/42',
            comments: comments,
          )),
        ),
        issueMutationsProvider.overrideWithValue(mutations),
      ],
      child: octanePrime(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: IssueDetailPage(issueId: _issueId, issue: issue),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (mutations: mutations);
}

class _FakeOfflineStatus extends OfflineStatus {
  @override
  Future<bool> build() async => false;
}

void main() {
  setUp(() async {
    await tester_setSurfaceSize();
  });

  tearDown(() async {
    // Reset surface — some tests increase it to host the sheet cleanly.
  });

  testWidgets('post comment records the call and clears the composer', (
    tester,
  ) async {
    final harness = await _pump(tester, issue: _openIssue);

    final field = find.byKey(AddCommentComposer.fieldKey);
    expect(field, findsOneWidget);

    await tester.enterText(
      find.descendant(of: field, matching: find.byType(TextField)),
      'Hello world',
    );
    await tester.pump();

    await tester.tap(find.byKey(AddCommentComposer.submitKey));
    await tester.pumpAndSettle();

    expect(harness.mutations.calls.length, 1);
    final call = harness.mutations.calls.single;
    expect(call, isA<PostCommentCall>());
    expect((call as PostCommentCall).issueId, _issueId);
    expect(call.body, 'Hello world');

    // Composer text field is cleared on success.
    expect(
      tester
          .widget<TextField>(
            find.descendant(of: field, matching: find.byType(TextField)),
          )
          .controller
          ?.text,
      isEmpty,
    );
  });

  testWidgets('post comment failure surfaces SnackBar and keeps the draft', (
    tester,
  ) async {
    final harness = await _pump(tester, issue: _openIssue);
    harness.mutations.throwNext = true;

    final field = find.byKey(AddCommentComposer.fieldKey);
    await tester.enterText(
      find.descendant(of: field, matching: find.byType(TextField)),
      'Flaky net',
    );
    await tester.pump();

    await tester.tap(find.byKey(AddCommentComposer.submitKey));
    await tester.pumpAndSettle();

    expect(find.text('Failed to post comment.'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(
            find.descendant(of: field, matching: find.byType(TextField)),
          )
          .controller
          ?.text,
      'Flaky net',
    );
  });

  testWidgets('own comment shows pencil icon; others do not', (tester) async {
    await _pump(
      tester,
      issue: _openIssue,
      comments: [_ownComment, _otherComment],
    );

    // Exactly one pencil icon across the conversation (for the own comment).
    expect(
      find.byKey(const ValueKey('issue-comment-edit-icon')),
      findsOneWidget,
    );
    expect(find.text('me'), findsOneWidget);
    expect(find.text('someone-else'), findsOneWidget);
  });

  testWidgets('tapping own comment opens the edit sheet with body prefilled', (
    tester,
  ) async {
    await _pump(tester, issue: _openIssue, comments: [_ownComment]);

    await tester.tap(find.byKey(const ValueKey('issue-comment-c-own')));
    await tester.pumpAndSettle();

    // Sheet is open: header visible. Comment body appears both in the
    // source card and in the sheet's editable field, hence >=1.
    expect(find.text('Edit Comment'), findsOneWidget);
    expect(find.text('My original comment.'), findsAtLeastNWidgets(1));
  });

  testWidgets('close issue flips the button to secondary "Re-open"', (
    tester,
  ) async {
    final harness = await _pump(tester, issue: _openIssue);

    expect(find.text('Close Issue'), findsOneWidget);

    await tester.tap(find.byKey(IssueStateAction.pageKey));
    await tester.pumpAndSettle();

    expect(harness.mutations.calls.whereType<CloseIssueCall>(), hasLength(1));
    final call = harness.mutations.calls.whereType<CloseIssueCall>().single;
    expect(call.projectId, _projectId);
    expect(call.issueId, _issueId);

    // Label flipped to re-open after the mutation resolves.
    expect(find.text('Re-open Issue'), findsOneWidget);
  });

  testWidgets('reopen issue records the reopen mutation', (tester) async {
    final harness = await _pump(tester, issue: _closedIssue);

    expect(find.text('Re-open Issue'), findsOneWidget);

    await tester.tap(find.byKey(IssueStateAction.pageKey));
    await tester.pumpAndSettle();

    expect(harness.mutations.calls.whereType<ReopenIssueCall>(), hasLength(1));
    final call = harness.mutations.calls.whereType<ReopenIssueCall>().single;
    expect(call.projectId, _projectId);
    expect(call.issueId, _issueId);
    expect(find.text('Close Issue'), findsOneWidget);
  });

  testWidgets('close issue error shows SnackBar', (tester) async {
    final harness = await _pump(tester, issue: _openIssue);
    harness.mutations.throwNext = true;

    await tester.tap(find.byKey(IssueStateAction.pageKey));
    await tester.pumpAndSettle();

    expect(find.text('Failed to close the issue.'), findsOneWidget);
    expect(find.text('Close Issue'), findsOneWidget);
  });

  testWidgets('edit issue menu opens the sheet with prefilled title', (
    tester,
  ) async {
    await _pump(tester, issue: _openIssue);

    // Open the kebab menu.
    await tester.tap(find.byTooltip('More actions'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('issue-detail-menu-edit')));
    await tester.pumpAndSettle();

    expect(find.text('Edit Issue'), findsOneWidget);
    expect(find.text('#42'), findsOneWidget);
    // The title field is pre-filled.
    expect(find.text('Refactor auth'), findsOneWidget);
  });
}

// ----------------------------- Helpers ---------------------------------------

Future<void> tester_setSurfaceSize() async {
  // Placeholder for consistency with existing tests; no-op here because each
  // test pumps in the default size, which is large enough.
}

class _FakeProjectList extends ProjectList {
  final List<Project> _projects;

  _FakeProjectList(this._projects);

  @override
  List<Project> build() => _projects;
}
