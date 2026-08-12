import AppIntents
import Foundation
import SwiftUI
import WidgetKit

struct GHTodosWidget: Widget {
    let kind = "GHTodosWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: SelectProjectIntent.self,
            provider: TodosTimelineProvider()
        ) { entry in
            TodosWidgetView(entry: entry)
        }
        .configurationDisplayName("GH Todos")
        .description("Shows todos from a selected GitHub Project.")
        .supportedFamilies([
            .systemSmall, .systemMedium, .systemLarge,
        ])
    }
}

struct TodosWidgetView: View {
    let entry: TodosEntry

    private var uri: URL {
        if case let .content(project, _) = entry.state {
            return URL(string: "ghtodos://local/project/\(project.id)")!
        }
        return URL(string: "ghtodos://local/")!
    }

    var body: some View {
        VStack(alignment: .leading) {
            switch entry.state {
            case let .content(project, todos):
                WidgetHeader(project: project, updatedAt: entry.date)
                TodosList(project: project, todos: todos)
            case .unconfigured:
                NoProjectView()
            case .projectUnavailable:
                ProjectUnavailableView()
            case let .error(failure, diagnosticID, occurredAt):
                WidgetErrorView(
                    failure: failure,
                    diagnosticID: diagnosticID,
                    occurredAt: occurredAt
                )
            }
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .topLeading
        )
        .containerBackground(.clear, for: .widget)
        .widgetURL(uri)
    }
}

private struct NoProjectView: View {
    var body: some View {
        VStack(alignment: .center) {
            Text("GH Todos")
            Text(
                "No project configured. Please select a project in the widget configuration."
            )
            .font(.system(size: 14))
            .fontWeight(.light)
        }
    }
}

private struct ProjectUnavailableView: View {
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Text("GH Todos")
                .font(.headline)
            Text("The selected project is unavailable. Reconfigure this widget to select a project.")
                .font(.system(size: 14))
                .fontWeight(.light)
                .multilineTextAlignment(.center)
        }
    }
}

private struct WidgetErrorView: View {
    let failure: WidgetRenderFailure
    let diagnosticID: String
    let occurredAt: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("GH Todos could not refresh", systemImage: "exclamationmark.triangle")
                .font(.headline)
            Text("Try refreshing the widget. If this continues, open the app and check the project configuration.")
                .font(.system(size: 13))
                .fontWeight(.light)
            Spacer(minLength: 0)
            Text("\(failure.code) · \(failure.stage)")
                .font(.caption.monospaced())
            Text("\(diagnosticID) · \(occurredAt.formatted(date: .omitted, time: .shortened))")
                .font(.caption2.monospaced())
                .foregroundStyle(.secondary)
        }
    }
}

private struct WidgetHeader: View {
    @Environment(\.widgetFamily) private var family

    let project: WidgetProject
    let updatedAt: Date

    private var titleFont: Font {
        switch family {
        case .systemSmall:
            .caption.weight(.semibold)
        default:
            .headline.weight(.semibold)
        }
    }

    private var showsLastUpdatedHint: Bool {
        switch family {
        case .systemMedium, .systemLarge:
            true
        default:
            false
        }
    }

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Text(project.name)
                .font(titleFont)
                .foregroundStyle(Color.primary)
                .lineLimit(1)

            if showsLastUpdatedHint {
                LastUpdatedHint(updatedAt: updatedAt)
                    .fixedSize(horizontal: true, vertical: false)
            }

            Spacer(minLength: 0)

            Button(intent: RefreshIssueIntent()) {
                Image(systemName: "arrow.clockwise.circle")
                    .font(
                        .system(
                            size: family == .systemSmall ? 16 : 18,
                            weight: .semibold
                        )
                    )
                    .frame(
                        width: family == .systemSmall ? 36 : 42,
                        height: family == .systemSmall ? 30 : 34
                    )
            }
            .buttonStyle(.borderless)
            .tint(WidgetPalette.primary)
            .accessibilityLabel("Refresh Todos")
        }
    }
}

private struct LastUpdatedHint: View {
    let updatedAt: Date

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "clock.arrow.circlepath")
            Text("Updated")
            Text(updatedAt, format: .dateTime.hour().minute())
        }
        .font(.caption2.weight(.medium))
        .foregroundStyle(WidgetPalette.muted.opacity(0.8))
        .lineLimit(1)
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial, in: Capsule())
        .accessibilityLabel("Last updated \(updatedAt.formatted(date: .omitted, time: .shortened))")
    }
}

private struct TodosList: View {
    @Environment(\.widgetFamily) private var family

    let project: WidgetProject
    let todos: [Todo]

    private var visibleTodos: [Todo] {
        switch family {
        case .systemLarge:
            Array(todos.prefix(6))
        case .systemMedium:
            Array(todos.prefix(2))
        default:
            Array(todos.prefix(1))
        }
    }

    var body: some View {
        Group {
            if todos.isEmpty {
                EmptyTodosState()
            } else if family == .systemSmall {
                SmallTodoCard(todo: visibleTodos.first)
            } else {
                Grid {
                    ForEach(0..<6) { index in
                        GridRow {
                            if index < self.visibleTodos.count {
                                TodoRow(
                                    project: project,
                                    todo: self.visibleTodos[index]
                                )
                            } else {
                                Color.clear
                                    .frame(
                                        maxWidth: .infinity,
                                        maxHeight: .infinity
                                    )
                            }
                        }
                    }
                }
            }
        }
    }
}

private struct TodoRow: View {
    @Environment(\.widgetFamily) private var family

    let project: WidgetProject
    let todo: Todo

    private var accent: PriorityStyle? {
        todo.priority.map(PriorityStyle.init(priority:))
    }

    private var rowFont: Font {
        switch family {
        case .systemMedium:
            .callout.weight(.light)
        default:
            .subheadline.weight(.light)
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(accent?.foreground ?? Color.clear)
                .frame(width: 4)

            HStack(alignment: .center, spacing: 8) {
                Link(
                    destination: URL(
                        string:
                            "ghtodos://local/project/\(project.id)/issue/\(todo.id)"
                    )!
                ) {
                    HStack(alignment: .center, spacing: 7) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(todo.title)
                                .font(rowFont)
                                .foregroundStyle(
                                    todo.closed
                                        ? Color.secondary : Color.primary
                                )
                                .strikethrough(todo.closed)
                                .lineLimit(1)

                            if let dueDate = todo.dueDate {
                                Label(
                                    formatDueDate(dueDate),
                                    systemImage: "calendar"
                                )
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(
                                    todo.closed
                                        ? Color.secondary : WidgetPalette.muted
                                )
                                .lineLimit(1)
                                .labelStyle(.titleAndIcon)
                            }
                        }

                        Spacer()
                    }
                }

                if todo.closed {
                    Button(intent: ReopenTodoIntent(issueId: todo.id)) {
                        TodoStateIcon(systemName: "checkmark.circle")
                    }
                    .buttonStyle(.borderless)
                    .tint(WidgetPalette.primary)
                    .accessibilityLabel("Reopen Todo")
                } else {
                    Button(intent: CloseTodoIntent(issueId: todo.id)) {
                        TodoStateIcon(systemName: "circle")
                    }
                    .buttonStyle(.borderless)
                    .tint(WidgetPalette.primary)
                    .accessibilityLabel("Close Todo")
                }
            }
            .padding(.leading, 10)
            .padding(.trailing, 6)
            .padding(.vertical, family == .systemMedium ? 6 : 4)
        }
        .background(
            rowBackground,
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .opacity(todo.closed ? 0.58 : 1)
        //.frame(height: 18)
    }

    private var rowBackground: Color {
        if let accent {
            return accent.background.opacity(todo.closed ? 0.45 : 0.72)
        }
        return Color(.secondarySystemBackground)
    }
}

private struct TodoStateIcon: View {
    @Environment(\.widgetFamily) private var family

    let systemName: String

    private var size: CGSize {
        switch family {
        case .systemMedium:
            CGSize(width: 38, height: 28)
        default:
            CGSize(width: 34, height: 26)
        }
    }

    var body: some View {
        Image(systemName: systemName)
            .font(
                .system(
                    size: family == .systemMedium ? 19 : 17,
                    weight: .medium
                )
            )
            .frame(width: size.width, height: size.height)
    }
}

private struct SmallTodoCard: View {
    let todo: Todo?

    private var accent: PriorityStyle? {
        todo?.priority.map(PriorityStyle.init(priority:))
    }

    var body: some View {
        if let todo {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(accent?.foreground ?? Color.clear)
                        .frame(width: 4)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(todo.title)
                            .font(.headline.weight(.light).pointSize(14))
                            .foregroundStyle(
                                todo.closed ? Color.secondary : Color.primary
                            )
                            .strikethrough(todo.closed)
                            .lineLimit(3)

                        HStack {
                            if let dueDate = todo.dueDate {
                                Label(
                                    formatDueDate(dueDate),
                                    systemImage: "calendar"
                                )
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(WidgetPalette.muted)
                                .lineLimit(1)
                                .layoutPriority(1)
                            }

                            if let priority = todo.priority {
                                Spacer()
                                Text(priorityLabel(priority))
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(
                                        accent?.foreground
                                            ?? WidgetPalette.muted
                                    )
                                    .lineLimit(1)
                            }
                        }
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background(
                    cardBackground,
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
                .clipShape(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
                .opacity(todo.closed ? 0.58 : 1)
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .topLeading
            )
        }
    }

    private var cardBackground: Color {
        if let accent {
            return accent.background.opacity(todo?.closed == true ? 0.45 : 0.72)
        }
        return Color(.secondarySystemBackground)
    }
}

private struct EmptyTodosState: View {
    @Environment(\.widgetFamily) private var family

    var body: some View {
        VStack(spacing: family == .systemSmall ? 6 : 8) {
            Image(systemName: "checkmark.circle")
                .font(
                    .system(
                        size: family == .systemSmall ? 24 : 30,
                        weight: .medium
                    )
                )
                .foregroundStyle(WidgetPalette.primary)

            Text("all done for now")
                .font(
                    family == .systemSmall
                        ? .caption.weight(.semibold)
                        : .callout.weight(.semibold)
                )
                .foregroundStyle(WidgetPalette.muted)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding(.bottom, 8)
    }
}

private struct PriorityStyle {
    let foreground: Color
    let background: Color

    init(priority: TodoPriority) {
        switch priority {
        case .urgent:
            foreground = Color(hex: 0x93000A)
            background = Color(hex: 0xFFDAD6)
        case .high:
            foreground = Color(hex: 0xB84B00)
            background = Color(hex: 0xFFDBCC)
        case .medium:
            foreground = Color(hex: 0x725C00)
            background = Color(hex: 0xFFE084)
        case .low:
            foreground = Color(hex: 0x42474E)
            background = Color(hex: 0xDEE3EB)
        case .trivial:
            foreground = Color(hex: 0x727785)
            background = Color(hex: 0xF0F1F5)
        }
    }
}

private enum WidgetPalette {
    static let primary = Color(hex: 0x0051AE)
    static let muted = Color(hex: 0x424753)
}

private func priorityLabel(_ priority: TodoPriority) -> String {
    switch priority {
    case .urgent:
        "Urgent"
    case .high:
        "High Priority"
    case .medium:
        "Medium Priority"
    case .low:
        "Low Priority"
    case .trivial:
        "Trivial"
    }
}

private func formatDueDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat =
        Calendar.current.component(.year, from: date)
            == Calendar.current.component(.year, from: Date())
        ? "MMM d"
        : "MMM d, yyyy"
    return formatter.string(from: date)
}

extension Color {
    fileprivate init(hex: Int) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

let previewProject = WidgetProject(
    id: "id",
    name: "MyProject",
    ownerLogin: "cbue",
    issueQuery: WidgetProject.defaultIssueQuery,
    dueDateFieldId: "",
    priorityFieldId: "",
    priorityOptionMap: [:]
)

let previewTodos: [Todo] = [
    Todo(
        id: "1",
        title: "Ship widget priority styling",
        number: 13,
        priority: .urgent,
        dueDate: Date().addingTimeInterval(86_400)
    ),
    Todo(
        id: "2",
        title: "Review GitHub project sync",
        number: 5,
        priority: .high,
        dueDate: Date().addingTimeInterval(259_200)
    ),
    Todo(
        id: "3",
        title: "Call Mum",
        number: 1,
        closed: true,
        priority: .low,
        dueDate: Date().addingTimeInterval(-86_400)
    ),
    Todo(
        id: "4",
        title: "Play Games",
        number: 1337,
        priority: .medium
    ),
    Todo(
        id: "5",
        title: "Other Things",
        number: 2,
        closed: true,
        priority: .trivial
    ),
    Todo(
        id: "6",
        title: "Some Stuff To Do that has a very long name",
        number: 42
    ),
]

#Preview("Unconfigured Widget", as: .systemSmall) {
    GHTodosWidget()
} timeline: {
    TodosEntry(date: Date(), state: .unconfigured)
}

#Preview("Large Widget", as: .systemLarge) {
    GHTodosWidget()
} timeline: {
    TodosEntry(
        date: Date(timeIntervalSinceReferenceDate: 777_649_920),
        state: .content(project: previewProject, todos: previewTodos)
    )
}

#Preview("Large Widget With Less Todos", as: .systemLarge) {
    GHTodosWidget()
} timeline: {
    TodosEntry(date: Date(), state: .content(project: previewProject, todos: Array(previewTodos.dropFirst(3))))
}

#Preview("Large Empty Widget", as: .systemLarge) {
    GHTodosWidget()
} timeline: {
    TodosEntry(date: Date(), state: .content(project: previewProject, todos: []))
}

#Preview("Medium Widget", as: .systemMedium) {
    GHTodosWidget()
} timeline: {
    TodosEntry(
        date: Date(timeIntervalSinceReferenceDate: 777_649_920),
        state: .content(project: previewProject, todos: previewTodos)
    )
}

#Preview("Medium Empty Widget", as: .systemMedium) {
    GHTodosWidget()
} timeline: {
    TodosEntry(date: Date(), state: .content(project: previewProject, todos: []))
}

#Preview("Small Widget", as: .systemSmall) {
    GHTodosWidget()
} timeline: {
    TodosEntry(date: Date(), state: .content(project: previewProject, todos: previewTodos))
}

#Preview("Small Widget Closed Todo", as: .systemSmall) {
    GHTodosWidget()
} timeline: {
    TodosEntry(
        date: Date(),
        state: .content(project: previewProject, todos: [
            Todo(
                id: "1",
                title: "Ship widget priority styling",
                number: 13,
                closed: true,
                priority: .urgent,
                dueDate: Date().addingTimeInterval(86_400)
            )
        ])
    )
}

#Preview("Small Widget No Priority", as: .systemSmall) {
    GHTodosWidget()
} timeline: {
    TodosEntry(
        date: Date(),
        state: .content(project: previewProject, todos: [
            Todo(
                id: "1",
                title: "Ship widget priority styling",
                number: 13,
                dueDate: Date().addingTimeInterval(86_400)
            )
        ])
    )
}

#Preview("Small Empty Widget", as: .systemSmall) {
    GHTodosWidget()
} timeline: {
    TodosEntry(date: Date(), state: .content(project: previewProject, todos: []))
}

#Preview("Project Unavailable", as: .systemSmall) {
    GHTodosWidget()
} timeline: {
    TodosEntry(date: Date(), state: .projectUnavailable)
}

#Preview("Widget Error", as: .systemMedium) {
    GHTodosWidget()
} timeline: {
    TodosEntry(
        date: Date(),
        state: .error(
            WidgetRenderFailure(error: GraphQLClient.Errors.missingToken, stage: "timeline"),
            diagnosticID: "DEMO1234",
            occurredAt: Date()
        )
    )
}
