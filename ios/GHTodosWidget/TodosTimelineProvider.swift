import Foundation
import WidgetKit

enum TodosRenderState {
    case content(project: WidgetProject, todos: [Todo])
    case unconfigured
    case projectUnavailable
    case error(WidgetRenderFailure, diagnosticID: String, occurredAt: Date)
}

struct TodosEntry: TimelineEntry {
    let date: Date
    let state: TodosRenderState
}

struct TodosTimelineProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> TodosEntry {
        WidgetDiagnostics.event("placeholder")
        return demoEntry()
    }

    func snapshot(for configuration: SelectProjectIntent, in context: Context)
        async -> TodosEntry
    {
        WidgetDiagnostics.event("snapshot", details: ["is_preview": context.isPreview])
        return context.isPreview ? demoEntry() : await entry(for: configuration)
    }

    func timeline(for configuration: SelectProjectIntent, in context: Context)
        async -> Timeline<TodosEntry>
    {
        let diagnosticID = WidgetDiagnostics.identifier()
        WidgetDiagnostics.event("timeline_started", diagnosticID: diagnosticID, details: [
            "has_configuration": configuration.projectID != nil,
        ])

        let entry = await entry(for: configuration, diagnosticID: diagnosticID)
        let refreshMinutes: Int
        let policy: TimelineReloadPolicy
        switch entry.state {
        case .content:
            refreshMinutes = 60
            policy = .after(Date().addingTimeInterval(60 * 60))
        default:
            refreshMinutes = 15
            policy = .after(Date().addingTimeInterval(15 * 60))
        }
        WidgetDiagnostics.event("timeline_finished", diagnosticID: diagnosticID, details: [
            "reload_minutes": refreshMinutes,
        ])
        return Timeline(entries: [entry], policy: policy)
    }

    private func entry(
        for configuration: SelectProjectIntent,
        diagnosticID: String? = nil
    ) async -> TodosEntry {
        let now = Date()
        guard configuration.projectID != nil else {
            WidgetDiagnostics.event("configuration_missing", diagnosticID: diagnosticID)
            return TodosEntry(date: now, state: .unconfigured)
        }

        let cacheResult = ProjectCache.read()
        WidgetDiagnostics.event("cache_read", diagnosticID: diagnosticID, details: [
            "result": cacheResult.diagnosticCode,
            "project_count": cacheResult.projects?.count ?? 0,
        ])
        guard let projects = cacheResult.projects else {
            let id = diagnosticID ?? WidgetDiagnostics.identifier()
            let failure = WidgetRenderFailure(
                error: CacheError(result: cacheResult),
                stage: "cache"
            )
            WidgetDiagnostics.failure(CacheError(result: cacheResult), diagnosticID: id, stage: "cache")
            return TodosEntry(date: now, state: .error(failure, diagnosticID: id, occurredAt: now))
        }
        guard let project = projects.first(where: { $0.id == configuration.projectID }) else {
            WidgetDiagnostics.event("configured_project_unavailable", diagnosticID: diagnosticID)
            return TodosEntry(date: now, state: .projectUnavailable)
        }

        let id = diagnosticID ?? WidgetDiagnostics.identifier()
        do {
            let todos = try await GraphQLClient.queryProjectIssues(
                projectId: project.id,
                issueQuery: project.issueQuery
            )
            let orderedTodos = orderTodos(todos: todos)
            WidgetDiagnostics.event("todos_loaded", diagnosticID: id, details: ["todo_count": todos.count])
            return TodosEntry(date: now, state: .content(project: project, todos: orderedTodos))
        } catch {
            WidgetDiagnostics.failure(error, diagnosticID: id, stage: "timeline")
            return TodosEntry(
                date: now,
                state: .error(
                    WidgetRenderFailure(error: error, stage: "timeline"),
                    diagnosticID: id,
                    occurredAt: now
                )
            )
        }
    }
}

struct CacheError: Error {
    let result: ProjectCacheResult
}

private func demoEntry() -> TodosEntry {
    TodosEntry(
        date: Date(),
        state: .content(project: previewProject, todos: previewTodos)
    )
}
