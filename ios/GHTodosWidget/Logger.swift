import Foundation
import os

enum WidgetDiagnostics {
    private static let logger = Logger(
        subsystem: "ch.cbue.ghTodos",
        category: "widget"
    )

    static func identifier() -> String {
        String(UUID().uuidString.prefix(8)).uppercased()
    }

    static func event(
        _ name: String,
        diagnosticID: String? = nil,
        details: [String: CustomStringConvertible] = [:]
    ) {
        let fields = details
            .sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: " ")
        let correlation = diagnosticID.map { " diagnostic_id=\($0)" } ?? ""
        logger.info("event=\(name, privacy: .public)\(correlation, privacy: .public) \(fields, privacy: .public)")
    }

    static func failure(
        _ error: Error,
        diagnosticID: String,
        stage: String
    ) {
        let classified = WidgetRenderFailure(error: error, stage: stage)
        logger.error("event=render_failure diagnostic_id=\(diagnosticID, privacy: .public) stage=\(classified.stage, privacy: .public) code=\(classified.code, privacy: .public)")
    }

    static func decodingFailure(_ error: Error) {
        let kind: String
        switch error {
        case DecodingError.dataCorrupted: kind = "data_corrupted"
        case DecodingError.keyNotFound: kind = "key_not_found"
        case DecodingError.typeMismatch: kind = "type_mismatch"
        case DecodingError.valueNotFound: kind = "value_not_found"
        default: kind = "unknown"
        }
        logger.error("event=graphql_decode_failed class=\(kind, privacy: .public)")
    }
}

struct WidgetRenderFailure: Equatable {
    let code: String
    let stage: String

    init(error: Error, stage: String) {
        self.stage = stage
        if let error = error as? GraphQLClient.Errors {
            code = error.diagnosticCode
        } else if let error = error as? CacheError {
            code = error.result.diagnosticCode
        } else if error is DecodingError {
            code = "decode_failed"
        } else if error is URLError {
            code = "transport_failed"
        } else {
            code = "unexpected"
        }
    }
}
