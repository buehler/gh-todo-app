
import AppIntents
import Foundation
import WidgetKit
import os

struct ReopenTodoIntent: AppIntent {
    static var title: LocalizedStringResource = "Reopen Todo"

    @Parameter(title: "Issue ID") var issueId: String

    init() {}

    init(issueId: String) {
        self.issueId = issueId
    }

    func perform() async throws -> some IntentResult {
        logger.info("reopen issue \(issueId)")
        try await GraphQLClient.reopenIssue(issueId: issueId)
        WidgetCenter.shared.reloadTimelines(ofKind: "GHTodosWidget")
        return .result()
    }
}
