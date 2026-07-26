
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
        let diagnosticID = WidgetDiagnostics.identifier()
        WidgetDiagnostics.event("reopen_todo_started", diagnosticID: diagnosticID)
        do {
            try await GraphQLClient.reopenIssue(issueId: issueId)
            WidgetCenter.shared.reloadTimelines(ofKind: "GHTodosWidget")
            WidgetDiagnostics.event("reopen_todo_succeeded", diagnosticID: diagnosticID)
            return .result()
        } catch {
            WidgetDiagnostics.failure(error, diagnosticID: diagnosticID, stage: "reopen_todo")
            throw error
        }
    }
}
