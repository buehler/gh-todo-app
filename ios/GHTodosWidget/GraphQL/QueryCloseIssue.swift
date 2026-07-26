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

        let response: Response
        do {
            response = try JSONDecoder().decode(Response.self, from: result)
        } catch {
            WidgetDiagnostics.decodingFailure(error)
            throw Errors.malformedResponse
        }
        guard response.data?.closeIssue != nil else {
            throw Errors.malformedResponse
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
