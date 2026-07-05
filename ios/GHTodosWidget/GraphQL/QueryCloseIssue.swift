import Foundation

extension GraphQLClient {
    static func closeIssue(issueId: String) async throws {
        struct Response: Decodable {
            let data: ResponseData?
        }

        struct ResponseData: Decodable {
            let closeIssue: MutationPayload?
        }

        struct MutationPayload: Decodable {}

        let query = GraphQLPayload(
            query: _queryCloseIssue,
            variables: [
                "issueId": issueId
            ]
        )
        let result = try await fetch(query)

        do {
            _ = try JSONDecoder().decode(Response.self, from: result)
        } catch {
            throw Errors.noResult
        }
    }
}

private let _queryCloseIssue = """
mutation CloseIssue($issueId: ID!) {
  closeIssue(input: { issueId: $issueId }) {
    issue {
      id
      state
      closedAt
      updatedAt
    }
  }
}
"""
