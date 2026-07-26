import Flutter
import os
import UIKit
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
    func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
        GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
        registerWidgetProjectChannel(engineBridge)
    }
    
    private let logger = Logger(subsystem: "ch.cbue.ghTodos", category: "main")
    
    private let appGroupId = "group.ch.cbue.GH-Todos"
    private let fileName = "projects.json"
    private let channelName = "ch.cbue.ghTodos/widget_project_cache"
    
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
