import Flutter
import os
import Security
import UIKit
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        migrateGithubPATAccessibility() // TODO: remove after next version.
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
        GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
        registerWidgetProjectChannel(engineBridge)
    }
    
    private let logger = Logger(subsystem: "ch.cbue.ghTodos", category: "main")
    
    private let appGroupId = "group.ch.cbue.GH-Todos"
    private let fileName = "projects.json"
    private let channelName = "ch.cbue.ghTodos/widget_project_cache"

    private func migrateGithubPATAccessibility() {
        logger.info("event=pat_accessibility_migration_started")
        let outcome = PATAccessibilityMigrator.migrate()
        switch outcome {
        case .migrated:
            logger.info("event=pat_accessibility_migration_migrated")
        case .noItem:
            logger.info("event=pat_accessibility_migration_no_item")
        case .deferredForProtectedData:
            logger.info("event=pat_accessibility_migration_deferred_for_protected_data")
        case let .failed(status):
            logger.error("event=pat_accessibility_migration_failed status_category=\(PATAccessibilityMigrator.statusCategory(for: status), privacy: .public)")
        }
    }
    
    private func registerWidgetProjectChannel(_ bridge: FlutterImplicitEngineBridge) {
        let channel = FlutterMethodChannel(
            name: channelName,
            binaryMessenger: bridge.applicationRegistrar.messenger()
        )
        logger.debug("event=widget_cache_channel_created")
        
        channel.setMethodCallHandler { [weak self] call, result in
            guard let self else { return }
            
            logger.debug("event=widget_cache_method_received method=\(call.method, privacy: .public)")
            switch call.method {
            case "writeProjectsJson":
                guard
                    let args = call.arguments as? [String: Any],
                    let json = args["json"] as? String
                else {
                    result(FlutterError(
                        code: "bad_arguments",
                        message: "Missing json argument.",
                        details: nil
                    ))
                    return
                }
                
                do {
                    try self.writeProjectsJson(json)
                    WidgetCenter.shared.reloadTimelines(ofKind: "GHTodosWidget")
                    self.logger.info("event=widget_cache_write_succeeded bytes=\(json.utf8.count, privacy: .public)")
                    result(nil)
                } catch {
                    self.logger.error("event=widget_cache_write_failed")
                    result(FlutterError(
                        code: "write_failed",
                        message: error.localizedDescription,
                        details: nil
                    ))
                }
                
            case "clearProjectsJson":
                do {
                    try self.clearProjectsJson()
                    WidgetCenter.shared.reloadTimelines(ofKind: "GHTodosWidget")
                    self.logger.info("event=widget_cache_clear_succeeded")
                    result(nil)
                } catch {
                    self.logger.error("event=widget_cache_clear_failed")
                    result(FlutterError(
                        code: "clear_failed",
                        message: error.localizedDescription,
                        details: nil
                    ))
                }
                
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }
    
    private func projectsFileURL() throws -> URL {
        guard let containerURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupId)
        else {
            throw NSError(
                domain: "WidgetProjectCache",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "App Group container unavailable."]
            )
        }
        
        return containerURL.appendingPathComponent(fileName)
    }
    
    private func writeProjectsJson(_ json: String) throws {
        let url = try projectsFileURL()
        try json.write(to: url, atomically: true, encoding: .utf8)
    }
    
    private func clearProjectsJson() throws {
        let url = try projectsFileURL()
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
    }
}

enum PATAccessibilityMigrationOutcome: Equatable {
    case migrated
    case noItem
    case deferredForProtectedData
    case failed(OSStatus)
}

enum PATAccessibilityMigrator {
    private static let accessGroup = "A7JX5S6CZ6.ch.cbue.GH-Todos"
    private static let account = "github.personal_access_token"
    private static let service = "flutter_secure_storage_service"

    static func migrate(
        protectedDataAvailable: Bool = UIApplication.shared.isProtectedDataAvailable
    ) -> PATAccessibilityMigrationOutcome {
        guard protectedDataAvailable else {
            return .deferredForProtectedData
        }

        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: account,
            kSecAttrService: service,
            kSecAttrAccessGroup: accessGroup,
        ]
        let status = SecItemUpdate(
            query as CFDictionary,
            updateAttributes() as CFDictionary
        )
        return outcome(for: status)
    }

    static func updateAttributes() -> [CFString: Any] {
        [kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock]
    }

    static func outcome(for status: OSStatus) -> PATAccessibilityMigrationOutcome {
        switch status {
        case errSecSuccess:
            .migrated
        case errSecItemNotFound:
            .noItem
        case errSecInteractionNotAllowed, errSecNotAvailable:
            .deferredForProtectedData
        default:
            .failed(status)
        }
    }

    static func statusCategory(for status: OSStatus) -> String {
        switch status {
        case errSecMissingEntitlement:
            "missing_entitlement"
        case errSecInteractionNotAllowed, errSecNotAvailable:
            "protected_data_unavailable"
        default:
            "other"
        }
    }
}
