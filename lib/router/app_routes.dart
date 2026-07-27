abstract final class AppRoutes {
  static const rootName = 'root';
  static const projectName = 'project';
  static const setupName = 'setup';
  static const settingsName = 'settings';
  static const applicationLogsName = 'applicationLogs';
  static const changelogName = 'changelog';
  static const issueDetailName = 'issueDetail';

  static const rootPath = '/';
  static const projectPath = '/project/:projectId';
  static const setupPath = '/setup';
  static const settingsPath = '/settings';
  static const applicationLogsPath = '/logs';
  static const changelogPath = '/changelog';
  static const issueDetailPath = 'issue/:issueId';

  static const projectIdParam = 'projectId';
  static const issueIdParam = 'issueId';
  static const freshQueryParam = 'fresh';

  static String projectLocation(String projectId) {
    return '/project/${Uri.encodeComponent(projectId)}';
  }

  static String issueDetailLocation({
    required String projectId,
    required String issueId,
  }) {
    return '${projectLocation(projectId)}/issue/${Uri.encodeComponent(issueId)}';
  }
}
