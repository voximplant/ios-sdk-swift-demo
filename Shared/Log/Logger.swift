/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

import VoxImplantSDK
import CocoaLumberjack

final class Logger {
    private static var ddLogLevel: DDLogLevel { .debug }
    private static var logDirectory: URL?
    private static let fileManager = FileManager.default
    private static var isConfigured = false

    static let appLogger = DDLog()
    static fileprivate let sdkLogger = DDLog()

    static func configure(appName: String) {
        // Configure log folder:
        guard !isConfigured else {
            Log.w("Logger.configure: called more than once, skipping")
            return
        }
        guard let documentsFolder = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Logger.configure: documents folder not found, skipping")
            return
        }
        let logsFolder = documentsFolder.appendingPathComponent("Logs")
        let bundleFolder = logsFolder.appendingPathComponent(appName)
        do {
            try fileManager.createDirectory(at: bundleFolder, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Logger.configure: error: \(error.localizedDescription)")
            return
        }
        logDirectory = bundleFolder

        // Configure logs:
        let logFileManager = DDLogFileManagerDefault(logsDirectory: bundleFolder.path)
        logFileManager.maximumNumberOfLogFiles = 1
        let fileLogger = DDFileLogger(logFileManager: logFileManager)
        fileLogger.rollingFrequency = TimeInterval(60 * 60 * 24)  // 24 hours
        fileLogger.maximumFileSize = 1024 * 1024 * 50 // 50MB
        appLogger.add(fileLogger, with: ddLogLevel) // Log app to file
        appLogger.add(DDOSLogger.sharedInstance, with: ddLogLevel) // Log app to console
        sdkLogger.add(fileLogger, with: ddLogLevel) // Log sdk to file

        // Configure Voximplant logs:
        VIClient.setLogLevel(.info)
        VIClient.writeLogsToFileLogger(fileLogger)

        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            Log.i("\(appName) Swift Demo v\(version) started", context: self)
        }

        isConfigured = true
    }

    static var logFilePath: URL? {
        guard let logDirectory = logDirectory else { return nil }
        do {
            let allFiles = try fileManager.contentsOfDirectory(atPath: logDirectory.path)
            Log.d("logFilePath: all files: \(allFiles)")
            guard let logFileName = allFiles.first(where: { $0.hasSuffix(".log") }) else { return nil }
            Log.d("logFilePath: log file name: \(logFileName)")
            let logFilePath = logDirectory.appendingPathComponent(logFileName)
            return logFilePath
        } catch {
            Log.w("logFilePath: error: \(error.localizedDescription)")
            return nil
        }
    }
}

fileprivate extension VIClient {
    class VILumberjackBridge: NSObject, VILogDelegate {
        static let instance = VILumberjackBridge()

        func didReceiveLogMessage(_ message: String, severity: VILogSeverity) {
            Logger.sdkLogger.log(
                asynchronous: severity != .error,
                message: DDLogMessage(
                    message: message,
                    level: .verbose,
                    flag: severity.flag,
                    context: 0,
                    file: "",
                    function: nil,
                    line: 0,
                    tag: nil,
                    options: [],
                    timestamp: nil
                )
            )
        }
    }

    static func writeLogsToFileLogger(_ logger: DDFileLogger) {
        VIClient.setLogDelegate(VILumberjackBridge.instance)
    }
}

fileprivate extension VILogSeverity {
    var flag: DDLogFlag {
        switch (self) {
        case .debug:
            return .debug
        case .error:
            return .error
        case .verbose:
            return .verbose
        case .warning:
            return .warning
        default:
            return .info
        }
    }
}
