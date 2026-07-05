import Foundation
import WidgetKit
import os

struct TodosEntry: TimelineEntry {
    let date: Date
    let project: WidgetProject?
    let todos: [Todo]
}

struct TodosTimelineProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> TodosEntry {
        TodosEntry(date: Date(), project: nil, todos: [])
    }

    func snapshot(for configuration: SelectProjectIntent, in context: Context)
        async -> TodosEntry
    {
        TodosEntry(date: Date(), project: nil, todos: [])
    }

    func timeline(for configuration: SelectProjectIntent, in context: Context)
        async -> Timeline<TodosEntry>
    {
        do {
            logger.debug("project: \(configuration.projectID ?? "nil")")
            guard
                let projectID = configuration.projectID,
                let project = ProjectCache.read().first(where: {
                    $0.id == projectID
                })
            else {
                return Timeline(
                    entries: [
                        TodosEntry(date: Date(), project: nil, todos: [])
                    ],
                    policy: .never
                )
            }

            let todos = try await GraphQLClient.queryProjectIssues(
                projectId: project.id
            )
            let orderedTodos = orderTodos(todos: todos)
            logger.debug("Found \(todos.count) todos")

            return Timeline(
                entries: [
                    TodosEntry(
                        date: Date(),
                        project: project,
                        todos: orderedTodos
                    )
                ],
                policy: .after(Date().addingTimeInterval(60 * 60))
            )
        } catch {
            logger.error("There was an error during creating the timeline: \(error)")
            return
                Timeline(
                    entries: [
                        TodosEntry(date: Date(), project: nil, todos: [])
                    ],
                    policy: .never
                )
        }
    }
}
