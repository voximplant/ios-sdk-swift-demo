/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

import VoxImplantSDK

protocol Loggable {
    var appName: String { get }
}

extension Loggable where Self: AnyObject {
    func configureDefaultLogging() {
        // Configure logs:
        Log.enable(level: .debug)
        // VIClient.writeLogsToFile()
        VIClient.setLogLevel(.info)
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            Log.i("\(appName) Swift Demo v\(version) started", context: self)
        }
    }
}

