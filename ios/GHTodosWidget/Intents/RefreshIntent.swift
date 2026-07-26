import AppIntents
import Foundation
import WidgetKit
import os

struct RefreshIssueIntent: AppIntent {
    static var title: LocalizedStringResource = "Refresh Todos"

    func perform() async throws -> some IntentResult {
        WidgetDiagnostics.event("refresh_requested")
        WidgetCenter.shared.reloadTimelines(ofKind: "GHTodosWidget")
        return .result()
    }
}
