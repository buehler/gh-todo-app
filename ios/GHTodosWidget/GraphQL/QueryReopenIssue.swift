import Foundation

extension GraphQLClient {
    static func reopenIssue(issueId: String) async throws {
        struct Response: Decodable {
            let data: ResponseData?
        }

        struct ResponseData: Decodable {
            let reopenIssue: MutationPayload?
        }

        struct MutationPayload: Decodable {}

        let query = GraphQLPayload(
            query: _queryReopenIssue,
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
        guard response.data?.reopenIssue != nil else {
            throw Errors.malformedResponse
        }
    }
}

private let _queryReopenIssue = """
mutation ReopenIssue($issueId: ID!) {
  reopenIssue(input: { issueId: $issueId }) {
    issue {
      id
      state
      updatedAt
    }
  }
}
"""
