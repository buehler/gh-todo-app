import AppIntents
import Foundation
import WidgetKit
import os

struct RefreshIssueIntent: AppIntent {
    static var title: LocalizedStringResource = "Refresh Todos"

    func perform() async throws -> some IntentResult {
        logger.info("refresh todos")
        WidgetCenter.shared.reloadTimelines(ofKind: "GHTodosWidget")
        return .result()
    }
}
