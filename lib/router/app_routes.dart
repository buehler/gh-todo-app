abstract final class AppRoutes {
  static const rootName = 'root';
  static const projectName = 'project';
  static const setupName = 'setup';
  static const settingsName = 'settings';
  static const applicationLogsName = 'applicationLogs';
  static const changelogName = 'changelog';
  static const issueDetailName = 'issueDetail';
  static const newTodoName = 'newTodo';

  static const rootPath = '/';
  static const projectPath = '/project/:projectId';
  static const setupPath = '/setup';
  static const settingsPath = '/settings';
  static const applicationLogsPath = '/logs';
  static const changelogPath = '/changelog';
  static const issueDetailPath = 'issue/:issueId';
  static const newTodoPath = 'new';

  static const projectIdParam = 'projectId';
  static const issueIdParam = 'issueId';
  static const freshQueryParam = 'fresh';
  static const returnToQueryParam = 'returnTo';

  static String projectLocation(String projectId) {
    return '/project/${Uri.encodeComponent(projectId)}';
  }

  static String issueDetailLocation({
    required String projectId,
    required String issueId,
  }) {
    return '${projectLocation(projectId)}/issue/${Uri.encodeComponent(issueId)}';
  }

  static String newTodoLocation(String projectId) {
    return '${projectLocation(projectId)}/new';
  }

  /// Only project-specific New todo routes may survive the connect flow.
  static String? newTodoReturnLocation(String? location) {
    if (location == null) return null;
    final uri = Uri.tryParse(location);
    if (uri == null || uri.hasScheme || uri.hasAuthority) return null;
    final segments = uri.pathSegments;
    if (segments.length != 3 ||
        segments[0] != 'project' ||
        segments[1].isEmpty ||
        segments[2] != 'new') {
      return null;
    }
    return newTodoLocation(segments[1]);
  }
}
