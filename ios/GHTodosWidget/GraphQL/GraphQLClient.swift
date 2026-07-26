import Foundation
internal import System

enum GraphQLClient {
    enum Errors: Error {
        case missingToken
        case transport
        case httpStatus(Int)
        case graphQLErrors(Int)
        case malformedResponse
        case missingProjectData

        var diagnosticCode: String {
            switch self {
            case .missingToken: "credential_missing"
            case .transport: "transport_failed"
            case .httpStatus: "http_failed"
            case .graphQLErrors: "graphql_failed"
            case .malformedResponse: "decode_failed"
            case .missingProjectData: "project_data_missing"
            }
        }
    }

    static private let url = URL(string: "https://api.github.com/graphql")!

    struct GraphQLPayload: Encodable {
        let query: String
        let variables: [String: String]?
    }

    private struct GraphQLErrorResponse: Decodable {
        let errors: [GraphQLError]?
    }

    private struct GraphQLError: Decodable {}

    static func fetch(_ query: GraphQLPayload) async throws -> Data {
        let token: String?
        do {
            token = try PATReader.readToken()
        } catch {
            WidgetDiagnostics.event("credential_read_failed")
            throw Errors.missingToken
        }
        guard let token, !token.isEmpty else {
            WidgetDiagnostics.event("credential_checked", details: ["present": false])
            throw Errors.missingToken
        }
        WidgetDiagnostics.event("credential_checked", details: ["present": true])

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(query)

        WidgetDiagnostics.event("graphql_request_started")
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            WidgetDiagnostics.event("graphql_transport_failed")
            throw Errors.transport
        }
        guard let httpResponse = response as? HTTPURLResponse else {
            throw Errors.transport
        }
        WidgetDiagnostics.event("graphql_response_received", details: [
            "http_status": httpResponse.statusCode,
        ])
        guard (200...299).contains(httpResponse.statusCode) else {
            throw Errors.httpStatus(httpResponse.statusCode)
        }

        let graphQLErrors = try? JSONDecoder().decode(GraphQLErrorResponse.self, from: data)
        if let count = graphQLErrors?.errors?.count, count > 0 {
            WidgetDiagnostics.event("graphql_errors_received", details: ["count": count])
            throw Errors.graphQLErrors(count)
        }
        return data
    }
}
