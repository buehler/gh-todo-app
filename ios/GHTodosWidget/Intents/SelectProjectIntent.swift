import AppIntents

struct SelectProjectIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Select Project"

    @Parameter(title: "Project", optionsProvider: ProjectIDOptionsProvider())
    var projectID: String?

    init(projectID: String) {
        self.projectID = projectID
    }

    init() {
    }
}

struct ProjectIDOptionsProvider: DynamicOptionsProvider {
    func results() async throws -> IntentItemCollection<String> {
        let items = ProjectCache.read().map { project in
            let title = "\(project.ownerLogin) / \(project.name)"

            return IntentItem(
                project.id,
                title: LocalizedStringResource(stringLiteral: title),
                subtitle: LocalizedStringResource(stringLiteral: project.id)
            )
        }

        return IntentItemCollection {
            IntentItemSection("Projects", items: items)
        }
    }
}
