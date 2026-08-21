import Foundation

extension GraphQLClient {
    static func queryProjectIssues(project: WidgetProject) async throws -> [Todo] {
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
            let optionId: String?
            let name: String?
            let date: String?
            let field: ProjectField?

            enum CodingKeys: String, CodingKey {
                case typeName = "__typename"
                case optionId
                case name
                case date
                case field
            }
        }

        struct ProjectField: Decodable {
            let id: String?
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
                "projectId": project.id,
                "issueQuery": project.issueQuery,
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

            let mappedFields = resolveMappedFields(
                fieldValues: (item?.fieldValues?.nodes ?? []).compactMap { fieldValue in
                    guard let fieldValue else { return nil }
                    return WidgetProjectFieldValue(
                        typeName: fieldValue.typeName,
                        fieldId: fieldValue.field?.id,
                        fieldName: fieldValue.field?.name,
                        optionId: fieldValue.optionId,
                        optionName: fieldValue.name,
                        date: fieldValue.date
                    )
                },
                project: project
            )

            return Todo(
                id: id,
                title: title,
                number: number,
                updatedAt: updatedAt,
                closed: closed,
                closedAt: content.closedAt.flatMap(parseGitHubTimestamp),
                priority: mappedFields.priority,
                dueDate: mappedFields.dueDate
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
