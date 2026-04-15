/// A single GitHub issue comment, flattened for rendering on the detail page.
class IssueComment {
  final String id;
  final String? authorLogin;
  final String body;
  final String createdAt;

  const IssueComment({
    required this.id,
    required this.authorLogin,
    required this.body,
    required this.createdAt,
  });
}

/// The deferred-loaded portion of an issue: its description, canonical URL,
/// and comment thread. Fetched by the detail page; kept separate from
/// [IssueData] so the feed query doesn't have to over-fetch.
class IssueDetails {
  final String? description;

  /// Canonical HTML URL of the issue on github.com. Null if the node resolves
  /// to something other than an Issue (shouldn't happen under normal flows).
  final String? url;
  final List<IssueComment> comments;

  const IssueDetails({
    required this.description,
    required this.url,
    required this.comments,
  });
}
