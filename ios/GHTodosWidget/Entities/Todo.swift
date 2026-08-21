import Foundation

struct Todo: Identifiable {
    let id: String
    let title: String
    let number: Int
    var updatedAt: Date = .distantPast
    var closed: Bool = false
    var closedAt: Date? = nil
    var priority: TodoPriority? = nil
    var dueDate: Date? = nil
}

enum TodoPriority: String {
    case urgent
    case high
    case medium
    case low
    case trivial
}

struct WidgetProjectFieldValue {
    let typeName: String?
    let fieldId: String?
    let fieldName: String?
    let optionId: String?
    let optionName: String?
    let date: String?
}

func resolveMappedFields(
    fieldValues: [WidgetProjectFieldValue],
    project: WidgetProject
) -> (priority: TodoPriority?, dueDate: Date?) {
    var priority: TodoPriority?
    var dueDate: Date?

    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
    dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
    dateFormatter.dateFormat = "yyyy-MM-dd"

    for fieldValue in fieldValues {
        if priority == nil,
            fieldValue.typeName == "ProjectV2ItemFieldSingleSelectValue",
            let priorityFieldId = project.priorityFieldId,
            fieldValue.fieldId == priorityFieldId,
            let optionId = fieldValue.optionId,
            let mappedValue = project.priorityOptionMap[optionId]
        {
            priority = TodoPriority(rawValue: mappedValue)
        }

        if dueDate == nil,
            fieldValue.typeName == "ProjectV2ItemFieldDateValue",
            let dueDateFieldId = project.dueDateFieldId,
            fieldValue.fieldId == dueDateFieldId,
            let date = fieldValue.date
        {
            dueDate = dateFormatter.date(from: date)
        }
    }

    return (priority, dueDate)
}

private let recentlyClosedWindow: TimeInterval = 3 * 24 * 60 * 60

func parseGitHubTimestamp(_ value: String) -> Date? {
    let fractionalFormatter = ISO8601DateFormatter()
    fractionalFormatter.formatOptions = [
        .withInternetDateTime,
        .withFractionalSeconds,
    ]

    let standardFormatter = ISO8601DateFormatter()
    standardFormatter.formatOptions = [.withInternetDateTime]

    return fractionalFormatter.date(from: value) ?? standardFormatter.date(from: value)
}

func shouldIncludeInTodoFeed(
    closed: Bool,
    closedAtRaw: String?,
    updatedAt: Date,
    now: Date = Date()
) -> Bool {
    guard closed else { return true }

    let closedAt: Date
    if let closedAtRaw {
        guard let parsedClosedAt = parseGitHubTimestamp(closedAtRaw) else {
            return false
        }
        closedAt = parsedClosedAt
    } else {
        closedAt = updatedAt
    }

    return closedAt >= now.addingTimeInterval(-recentlyClosedWindow)
}

func orderTodos(todos: [Todo]) -> [Todo] {
    let priorityRank: (TodoPriority?) -> Int = { priority in
        switch priority {
        case .urgent:
            return 0
        case .high:
            return 1
        case .medium:
            return 2
        case nil:
            return 3
        case .low:
            return 4
        case .trivial:
            return 5
        }
    }

    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt

    return todos.sorted { lhs, rhs in
        if lhs.closed != rhs.closed {
            return !lhs.closed
        }

        let lhsPriorityRank = priorityRank(lhs.priority)
        let rhsPriorityRank = priorityRank(rhs.priority)
        if lhsPriorityRank != rhsPriorityRank {
            return lhsPriorityRank < rhsPriorityRank
        }

        let lhsDueDate = lhs.dueDate.map { calendar.startOfDay(for: $0) }
        let rhsDueDate = rhs.dueDate.map { calendar.startOfDay(for: $0) }
        if lhsDueDate != nil || rhsDueDate != nil {
            if lhsDueDate == nil {
                return false
            }
            if rhsDueDate == nil {
                return true
            }
            if lhsDueDate != rhsDueDate {
                return lhsDueDate! < rhsDueDate!
            }
        }

        return lhs.updatedAt > rhs.updatedAt
    }
}
