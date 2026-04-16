import 'package:gh_todos/models/issue_data.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'selected_issue_provider.g.dart';

/// Transient store for the issue displayed in the detail pane on wide
/// (tablet-landscape / desktop) layouts. `null` = empty pane ("Select an
/// issue" placeholder).
///
/// Deliberately not persisted: a restart should bring the user back to an
/// empty detail pane rather than restore a possibly-stale selection. Deep
/// links (`/issue/:id`) still work — the list tile's open-helper sets this
/// on wide, and the router still push-routes on narrow.
@Riverpod(keepAlive: true)
class SelectedIssue extends _$SelectedIssue {
  @override
  IssueData? build() => null;

  void select(IssueData? issue) => state = issue;

  void clear() => state = null;
}
