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
        DDLog.add(fileLogger, with: ddLogLevel) // Log to file
        DDLog.add(DDOSLogger.sharedInstance, with: ddLogLevel) // Log to console

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
