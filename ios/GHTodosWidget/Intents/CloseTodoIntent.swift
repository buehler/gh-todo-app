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
        let diagnosticID = WidgetDiagnostics.identifier()
        WidgetDiagnostics.event("close_todo_started", diagnosticID: diagnosticID)
        do {
            try await GraphQLClient.closeIssue(issueId: issueId)
            WidgetCenter.shared.reloadTimelines(ofKind: "GHTodosWidget")
            WidgetDiagnostics.event("close_todo_succeeded", diagnosticID: diagnosticID)
            return .result()
        } catch {
            WidgetDiagnostics.failure(error, diagnosticID: diagnosticID, stage: "close_todo")
            throw error
        }
    }
}
