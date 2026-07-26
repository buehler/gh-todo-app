import Foundation

struct WidgetProject: Codable, Identifiable {
    let id: String
    let name: String
    let ownerLogin: String
    let dueDateFieldId: String?
    let priorityFieldId: String?
    let priorityOptionMap: [String: String]
}

enum ProjectCacheResult {
    case available([WidgetProject])
    case appGroupUnavailable
    case missing
    case unreadable
    case invalid

    var projects: [WidgetProject]? {
        guard case let .available(projects) = self else { return nil }
        return projects
    }

    var diagnosticCode: String {
        switch self {
        case .available: "available"
        case .appGroupUnavailable: "app_group_unavailable"
        case .missing: "cache_missing"
        case .unreadable: "cache_unreadable"
        case .invalid: "cache_invalid"
        }
    }
}

enum ProjectCache {
    static let appGroupId = "group.ch.cbue.GH-Todos"
    static let fileName = "projects.json"

    static func read() -> ProjectCacheResult {
        guard let containerURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupId)
        else {
            return .appGroupUnavailable
        }

        let url = containerURL.appendingPathComponent(fileName)
        guard FileManager.default.fileExists(atPath: url.path) else {
            return .missing
        }

        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            return .unreadable
        }

        do {
            return .available(try JSONDecoder().decode([WidgetProject].self, from: data))
        } catch {
            return .invalid
        }
    }
}
