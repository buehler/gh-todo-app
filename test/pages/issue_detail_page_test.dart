import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
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
  url: 'https://github.com/acme/repo/issues/42',
  body: '**Original** description.',
  bodyHtml: '<p><strong>Original</strong> description.</p>',
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
  url: 'https://github.com/acme/repo/issues/42',
  body: '**Original** description.',
  bodyHtml: '<p><strong>Original</strong> description.</p>',
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
  body: '**My** original comment.',
  bodyHtml: '<p><strong>My</strong> original comment.</p>',
  createdAt: '2026-04-13T10:00:00Z',
);

final _otherComment = IssueComment(
  id: 'c-other',
  authorLogin: 'someone-else',
  body: "Someone else's comment.",
  bodyHtml: "<p>Someone else's comment.</p>",
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
  Stream<List<IssueComment>>? commentsStream,
  FakeIssueMutations? mutations,
  Size surfaceSize = const Size(800, 1400),
}) async {
  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final fakeStorage = FakeFlutterSecureStorage(
    seed: {GithubTokenStorageService.tokenStorageKey: 'ghp_seed'},
  );
  final fakeMutations = mutations ?? FakeIssueMutations();
  final sessionPrefs = FakeSessionPrefsService(selectedProjectId: _projectId);
  final stream = commentsStream ?? Stream.value(comments);

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
        userInfoProvider.overrideWith((_) => Future.value(_viewer)),
        issueCommentsProvider(_issueId).overrideWith((ref) => stream),
        issueMutationsProvider.overrideWithValue(fakeMutations),
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
  return (mutations: fakeMutations);
}

class _FakeOfflineStatus extends OfflineStatus {
  @override
  Future<bool> build() async => false;
}

void main() {
  setUp(() async {
    await testerSetSurfaceSize();
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

    final textField = tester.widget<TextField>(
      find.descendant(of: field, matching: find.byType(TextField)),
    );
    expect(textField.controller?.text, isEmpty);
    expect(textField.focusNode?.hasFocus, isTrue);
  });

  testWidgets('modifier enter posts comment and clears the composer', (
    tester,
  ) async {
    final harness = await _pump(tester, issue: _openIssue);

    final field = find.byKey(AddCommentComposer.fieldKey);
    final textField = find.descendant(
      of: field,
      matching: find.byType(TextField),
    );
    expect(field, findsOneWidget);

    await tester.enterText(textField, 'Keyboard comment');
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();

    expect(harness.mutations.calls.length, 1);
    var call = harness.mutations.calls.single;
    expect(call, isA<PostCommentCall>());
    expect((call as PostCommentCall).issueId, _issueId);
    expect(call.body, 'Keyboard comment');
    expect(tester.widget<TextField>(textField).controller?.text, isEmpty);

    await tester.enterText(textField, 'Command comment');
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    await tester.pumpAndSettle();

    expect(harness.mutations.calls.length, 2);
    call = harness.mutations.calls.last;
    expect(call, isA<PostCommentCall>());
    expect((call as PostCommentCall).issueId, _issueId);
    expect(call.body, 'Command comment');
    expect(tester.widget<TextField>(textField).controller?.text, isEmpty);
    expect(tester.widget<TextField>(textField).focusNode?.hasFocus, isTrue);
  });

  testWidgets('shift enter does not post comment', (tester) async {
    final harness = await _pump(tester, issue: _openIssue);

    final field = find.byKey(AddCommentComposer.fieldKey);
    final textField = find.descendant(
      of: field,
      matching: find.byType(TextField),
    );
    expect(field, findsOneWidget);

    await tester.enterText(textField, 'Keyboard comment');
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pumpAndSettle();

    expect(harness.mutations.calls, isEmpty);
    expect(
      tester.widget<TextField>(textField).controller?.text,
      startsWith('Keyboard comment'),
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
    final textField = tester.widget<TextField>(
      find.descendant(of: field, matching: find.byType(TextField)),
    );
    expect(textField.controller?.text, 'Flaky net');
    expect(textField.focusNode?.hasFocus, isTrue);
  });

  testWidgets('composer remains visible when the detail content scrolls', (
    tester,
  ) async {
    await _pump(
      tester,
      issue: _openIssue,
      comments: _longCommentThread(),
      surfaceSize: const Size(390, 640),
    );

    await tester.drag(
      find.byKey(IssueDetailPage.scrollKey),
      const Offset(0, -900),
    );
    await tester.pumpAndSettle();

    final composerRect = tester.getRect(find.byKey(AddCommentComposer.pageKey));
    expect(composerRect.bottom, lessThanOrEqualTo(640));
    expect(composerRect.top, greaterThanOrEqualTo(0));
  });

  testWidgets('posting a comment scrolls the transcript to the bottom', (
    tester,
  ) async {
    final controller = StreamController<List<IssueComment>>();
    addTearDown(controller.close);
    final comments = _longCommentThread();
    const newComment = '''
Line one
Line two
Line three
Line four
Line five
Line six
Line seven''';
    final mutations = _RefreshingIssueMutations(
      onPost: () {
        controller.add([
          ...comments,
          IssueComment(
            id: 'c-new',
            authorLogin: 'me',
            body: newComment,
            bodyHtml: '<p>$newComment</p>',
            createdAt: '2026-04-13T12:30:00Z',
          ),
        ]);
      },
    );
    controller.add(comments);

    await _pump(
      tester,
      issue: _openIssue,
      commentsStream: controller.stream,
      mutations: mutations,
      surfaceSize: const Size(390, 640),
    );

    final scrollable = tester.widget<SingleChildScrollView>(
      find.byKey(IssueDetailPage.scrollKey),
    );
    final scrollController = scrollable.controller!;
    expect(scrollController.offset, 0);

    final field = find.byKey(AddCommentComposer.fieldKey);
    await tester.enterText(
      find.descendant(of: field, matching: find.byType(TextField)),
      newComment,
    );
    await tester.pump();

    await tester.tap(find.byKey(AddCommentComposer.submitKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    final postedComment = find.textContaining('Line one');
    expect(postedComment, findsOneWidget);
    final postedCommentRect = tester.getRect(postedComment);
    final composerRect = tester.getRect(find.byKey(AddCommentComposer.pageKey));
    expect(postedCommentRect.bottom, lessThanOrEqualTo(composerRect.top));
    expect(
      scrollController.offset,
      closeTo(scrollController.position.maxScrollExtent, 4),
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

  testWidgets('renders issue description and comments from html', (
    tester,
  ) async {
    await _pump(
      tester,
      issue: _openIssue,
      comments: [_ownComment, _otherComment],
    );

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(find.textContaining('Original'), findsOneWidget);
    expect(find.textContaining('description.'), findsOneWidget);

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(find.textContaining('original comment.'), findsOneWidget);
    expect(find.textContaining("Someone else's comment."), findsOneWidget);
  });

  testWidgets('renders empty description state', (tester) async {
    await _pump(tester, issue: _openIssue.copyWith(body: null, bodyHtml: null));

    expect(find.text('No description provided.'), findsOneWidget);
  });

  testWidgets('tapping own comment body does not open the edit sheet', (
    tester,
  ) async {
    await _pump(tester, issue: _openIssue, comments: [_ownComment]);

    await tester.tap(find.byKey(const ValueKey('issue-comment-c-own')));
    await tester.pumpAndSettle();

    expect(find.text('Edit Comment'), findsNothing);
  });

  testWidgets(
    'tapping own comment edit button opens sheet with body prefilled',
    (tester) async {
      await _pump(tester, issue: _openIssue, comments: [_ownComment]);

      await tester.tap(find.byKey(const ValueKey('issue-comment-edit-icon')));
      await tester.pumpAndSettle();

      expect(find.text('Edit Comment'), findsOneWidget);
      final field = tester.widget<TextField>(find.byType(TextField).last);
      expect(field.controller?.text, '**My** original comment.');
    },
  );

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

  testWidgets('edit issue menu opens the sheet with markdown body prefilled', (
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
    final fields = tester.widgetList<TextField>(find.byType(TextField));
    expect(
      fields.any(
        (field) => field.controller?.text == '**Original** description.',
      ),
      isTrue,
    );
  });
}

// ----------------------------- Helpers ---------------------------------------

Future<void> testerSetSurfaceSize() async {
  // Placeholder for consistency with existing tests; no-op here because each
  // test pumps in the default size, which is large enough.
}

class _FakeProjectList extends ProjectList {
  final List<Project> _projects;

  _FakeProjectList(this._projects);

  @override
  List<Project> build() => _projects;
}

List<IssueComment> _longCommentThread() {
  return [
    for (var i = 0; i < 14; i++)
      IssueComment(
        id: 'c-$i',
        authorLogin: i.isEven ? 'me' : 'someone-else',
        body:
            'Comment $i with enough text to build a useful transcript for scrolling.',
        bodyHtml:
            '<p>Comment $i with enough text to build a useful transcript for scrolling.</p>',
        createdAt: '2026-04-13T10:${i.toString().padLeft(2, '0')}:00Z',
      ),
  ];
}

class _RefreshingIssueMutations extends FakeIssueMutations {
  final VoidCallback onPost;

  _RefreshingIssueMutations({required this.onPost});

  @override
  Future<void> postComment({
    required String issueId,
    required String body,
  }) async {
    await super.postComment(issueId: issueId, body: body);
    onPost();
  }
}
