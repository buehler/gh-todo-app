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
        let cacheResult = ProjectCache.read()
        let projects = cacheResult.projects ?? []
        WidgetDiagnostics.event("configuration_options_loaded", details: [
            "cache_result": cacheResult.diagnosticCode,
            "project_count": projects.count,
        ])
        let items = projects.map { project in
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
