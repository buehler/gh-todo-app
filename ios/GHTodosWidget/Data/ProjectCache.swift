import Foundation

struct WidgetProject: Codable, Identifiable {
    static let defaultIssueQuery = "assignee:@me"

    let id: String
    let name: String
    let ownerLogin: String
    let issueQuery: String
    let dueDateFieldId: String?
    let priorityFieldId: String?
    let priorityOptionMap: [String: String]

    enum CodingKeys: String, CodingKey {
        case id, name, ownerLogin, issueQuery, dueDateFieldId, priorityFieldId, priorityOptionMap
    }

    init(
        id: String,
        name: String,
        ownerLogin: String,
        issueQuery: String = Self.defaultIssueQuery,
        dueDateFieldId: String?,
        priorityFieldId: String?,
        priorityOptionMap: [String: String]
    ) {
        self.id = id
        self.name = name
        self.ownerLogin = ownerLogin
        self.issueQuery = issueQuery
        self.dueDateFieldId = dueDateFieldId
        self.priorityFieldId = priorityFieldId
        self.priorityOptionMap = priorityOptionMap
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        ownerLogin = try container.decode(String.self, forKey: .ownerLogin)
        issueQuery = try container.decodeIfPresent(String.self, forKey: .issueQuery)
            ?? Self.defaultIssueQuery
        dueDateFieldId = try container.decodeIfPresent(String.self, forKey: .dueDateFieldId)
        priorityFieldId = try container.decodeIfPresent(String.self, forKey: .priorityFieldId)
        priorityOptionMap = try container.decodeIfPresent([String: String].self, forKey: .priorityOptionMap)
            ?? [:]
    }
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
