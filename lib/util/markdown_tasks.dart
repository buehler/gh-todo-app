/// Rewrites one GitHub-flavored Markdown task marker without touching the
/// surrounding text. The [taskIndex] is the zero-based source-order position
/// of the rendered task-list checkbox.
///
/// Returns `null` when the source does not contain that task. Callers must not
/// send an update in that case: it means the rendered HTML and Markdown no
/// longer describe the same task list.
String? toggleMarkdownTaskAtIndex(
  String markdown, {
  required int taskIndex,
  required bool checked,
}) {
  if (taskIndex < 0) return null;

  var activeFenceCharacter = '';
  var activeFenceLength = 0;
  var currentTaskIndex = 0;
  var sourceOffset = 0;
  final lines = markdown.split('\n');

  for (final line in lines) {
    final fence = _fencePattern.firstMatch(line);
    if (fence != null) {
      final marker = fence.group(1)!;
      if (activeFenceCharacter.isEmpty) {
        activeFenceCharacter = marker[0];
        activeFenceLength = marker.length;
      } else if (marker[0] == activeFenceCharacter &&
          marker.length >= activeFenceLength) {
        activeFenceCharacter = '';
        activeFenceLength = 0;
      }
      sourceOffset += line.length + 1;
      continue;
    }

    if (activeFenceCharacter.isNotEmpty) {
      sourceOffset += line.length + 1;
      continue;
    }

    final task = _taskPattern.firstMatch(line);
    if (task != null) {
      if (currentTaskIndex == taskIndex) {
        final matchedTask = task.group(0)!;
        final checkboxValueOffset =
            sourceOffset + task.start + matchedTask.lastIndexOf(task.group(1)!);
        return markdown.replaceRange(
          checkboxValueOffset,
          checkboxValueOffset + 1,
          checked ? 'x' : ' ',
        );
      }
      currentTaskIndex++;
    }

    sourceOffset += line.length + 1;
  }

  return null;
}

/// GitHub task lists can be unordered or ordered, with any normal list
/// indentation and optional blockquote prefixes. Group 1 is deliberately the
/// single state character so replacement cannot alter whitespace or markers.
final _taskPattern = RegExp(
  r'^[ \t]*(?:>[ \t]?)*[ \t]*(?:[-+*]|\d+[.)])[ \t]+\[([ xX])\]',
);

/// Fenced code is rendered as code, not as a task list. Skip its contents so
/// source indexing stays aligned with GitHub's rendered checkboxes.
final _fencePattern = RegExp(r'^[ \t]*(?:>[ \t]?)*(`{3,}|~{3,})');
