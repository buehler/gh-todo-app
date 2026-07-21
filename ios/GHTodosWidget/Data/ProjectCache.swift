import Foundation

struct WidgetProject: Codable, Identifiable {
    let id: String
    let name: String
    let ownerLogin: String
    let dueDateFieldId: String?
    let priorityFieldId: String?
    let priorityOptionMap: [String: String]
}

enum ProjectCache {
    static let appGroupId = "group.ch.cbue.GH-Todos"
    static let fileName = "projects.json"

    static func read() -> [WidgetProject] {
        guard
            let containerURL = FileManager.default
                .containerURL(forSecurityApplicationGroupIdentifier: appGroupId)
        else {
            return []
        }

        let url = containerURL.appendingPathComponent(fileName)

        guard let data = try? Data(contentsOf: url) else {
            return []
        }

        return (try? JSONDecoder().decode([WidgetProject].self, from: data))
            ?? []
    }
}
