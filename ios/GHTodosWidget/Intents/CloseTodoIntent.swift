import AppIntents
import Foundation
import WidgetKit
import os

struct CloseTodoIntent: AppIntent {
    static var title: LocalizedStringResource = "Close Todo"

    @Parameter(title: "Issue ID") var issueId: String

    init() {}

    init(issueId: String) {
        self.issueId = issueId
    }

    func perform() async throws -> some IntentResult {
        logger.info("close issue \(issueId)")
        try await GraphQLClient.closeIssue(issueId: issueId)
        WidgetCenter.shared.reloadTimelines(ofKind: "GHTodosWidget")
        return .result()
    }
}
