import Foundation
internal import System

enum GraphQLClient {
    enum Errors: Error {
        case noResult
    }
    
    static private let url: URL = URL(string:
        "https://api.github.com/graphql"
    )!

    struct GraphQLPayload: Encodable {
        let query: String
        let variables: [String: String]?
    }
    
    struct RateLimit: Codable {
        let cost: Int
        let limit: Int
        let remaining: Int
        let resetAt: String
    }

    static func fetch(_ query: GraphQLPayload) async throws -> Data {
        let token = try PATReader.readToken()
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(
            "Bearer \(token ?? "N/A")",
            forHTTPHeaderField: "Authorization"
        )

        request.httpBody = try JSONEncoder().encode(query)
        let (data, _) = try await URLSession.shared.data(for: request)

        return data
    }
}
