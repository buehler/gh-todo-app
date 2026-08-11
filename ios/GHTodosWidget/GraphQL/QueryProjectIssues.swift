import Foundation

extension GraphQLClient {
    static func queryProjectIssues(projectId: String, issueQuery: String) async throws -> [Todo] {
        struct Response: Decodable {
            let data: ResponseData?
        }

        struct ResponseData: Decodable {
            let node: ProjectNode?
        }

        struct ProjectNode: Decodable {
            let items: ProjectItems?
        }

        struct ProjectItems: Decodable {
            let nodes: [ProjectItem?]?
        }

        struct ProjectItem: Decodable {
            let fieldValues: FieldValues?
            let content: IssueContent?
        }

        struct FieldValues: Decodable {
            let nodes: [FieldValue?]?
        }

        struct FieldValue: Decodable {
            let typeName: String?
            let name: String?
            let date: String?
            let field: ProjectField?

            enum CodingKeys: String, CodingKey {
                case typeName = "__typename"
                case name
                case date
                case field
            }
        }

        struct ProjectField: Decodable {
            let name: String?
        }

        struct IssueContent: Decodable {
            let typeName: String?
            let id: String?
            let number: Int?
            let title: String?
            let updatedAt: String?
            let state: String?
            let closedAt: String?

            enum CodingKeys: String, CodingKey {
                case typeName = "__typename"
                case id
                case number
                case title
                case updatedAt
                case state
                case closedAt
            }
        }

        let query = GraphQLPayload(
            query: _queryProjectIssues,
            variables: [
                "projectId": projectId,
                "issueQuery": issueQuery,
            ]
        )
        let result = try await fetch(query)

        let response: Response
        do {
            response = try JSONDecoder().decode(Response.self, from: result)
        } catch {
            WidgetDiagnostics.decodingFailure(error)
            throw Errors.malformedResponse
        }

        guard response.data?.node != nil else {
            throw Errors.missingProjectData
        }

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatter.dateFormat = "yyyy-MM-dd"

        return response.data?.node?.items?.nodes?.compactMap { item in
            guard
                let content = item?.content,
                content.typeName == "Issue",
                let id = content.id,
                let title = content.title,
                let number = content.number,
                let updatedAtRaw = content.updatedAt,
                let updatedAt = parseGitHubTimestamp(updatedAtRaw),
                let state = content.state
            else {
                return nil
            }

            let closed = state == "CLOSED"
            guard shouldIncludeInTodoFeed(
                closed: closed,
                closedAtRaw: content.closedAt,
                updatedAt: updatedAt
            ) else {
                return nil
            }

            var priority: TodoPriority?
            var dueDate: Date?

            for fieldValue in item?.fieldValues?.nodes ?? [] {
                guard let fieldValue else { continue }

                if priority == nil,
                    fieldValue.typeName
                        == "ProjectV2ItemFieldSingleSelectValue",
                    fieldValue.field?.name == "Priority",
                    let priorityName = fieldValue.name?.lowercased()
                {
                    switch priorityName {
                    case "super high", "urgent":
                        priority = .urgent
                    case "high", "high priority":
                        priority = .high
                    case "medium", "medium priority":
                        priority = .medium
                    case "low", "lowest":
                        priority = .low
                    case "trivial":
                        priority = .trivial
                    default:
                        break
                    }
                } else if dueDate == nil,
                    fieldValue.typeName == "ProjectV2ItemFieldDateValue",
                    fieldValue.field?.name == "Due Date",
                    let date = fieldValue.date
                {
                    dueDate = dateFormatter.date(from: date)
                }
            }

            return Todo(
                id: id,
                title: title,
                number: number,
                updatedAt: updatedAt,
                closed: closed,
                closedAt: content.closedAt.flatMap(parseGitHubTimestamp),
                priority: priority,
                dueDate: dueDate
            )
        } ?? []
    }
}

private let _queryProjectIssues = """
    query ProjectAssignedItemsPage($projectId: ID!, $after: String, $issueQuery: String!) {
      node(id: $projectId) {
        ... on ProjectV2 {
          items(first: 100, after: $after, query: $issueQuery) {
            nodes {
              ...ProjectItemFields
            }
            pageInfo {
              hasNextPage
              endCursor
            }
          }
        }
      }
      rateLimit {
        cost
        limit
        remaining
        resetAt
      }
    }

    fragment ProjectItemFields on ProjectV2Item {
      id
      fieldValues(first: 15) {
        nodes {
          __typename
          ... on ProjectV2ItemFieldSingleSelectValue {
            optionId
            name
            field {
              ... on ProjectV2SingleSelectField {
                id
                name
              }
            }
          }
          ... on ProjectV2ItemFieldDateValue {
            date
            field {
              ... on ProjectV2Field {
                id
                name
              }
            }
          }
        }
      }
      content {
        __typename
        ... on Issue {
          id
          url
          number
          title
          createdAt
          updatedAt
          state
          closedAt
        }
      }
    }
    """
