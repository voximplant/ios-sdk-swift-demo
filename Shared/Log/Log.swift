/*
 *  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
 */

import CocoaLumberjackSwift

final class Log {
    private static func describe(_ object : AnyObject) -> String {
        if (object is String) {
            return "\(currentQueueName) | \(String(describing: object))"
        } else {
            return "\(currentQueueName) | \(String(describing: type(of: object))) <\(Unmanaged.passUnretained(object).toOpaque())>"
        }
    }

    private static var currentQueueName: String {
        let name = __dispatch_queue_get_label(nil)
        if let queue = String(cString: name, encoding: .utf8)?.components(separatedBy: ".").last {
            return queue.padding(toLength: 10, withPad: " ", startingAt: 0)
        }
        return "\(Unmanaged.passUnretained(Thread.current).toOpaque())".padding(toLength: 10, withPad: " ", startingAt: 0)
    }

    static func v(_ message: @autoclosure() -> String, context: AnyObject? = nil) {
        if let context = context {
            DDLogVerbose("#SD/V [\(describe(context))] \(message())", ddlog: Logger.appLogger)
        } else {
            DDLogVerbose("#SD/V [\(currentQueueName)] \(message())", ddlog: Logger.appLogger)
        }
    }

    static func d(_ message: @autoclosure() -> String, context: AnyObject? = nil) {
        if let context = context {
            DDLogDebug("#SD/D [\(describe(context))] \(message())", ddlog: Logger.appLogger)
        } else {
            DDLogDebug("#SD/D [\(currentQueueName)] \(message())", ddlog: Logger.appLogger)
        }
    }

    static func i(_ message: @autoclosure() -> String, context: AnyObject? = nil) {
        if let context = context {
            DDLogInfo("#SD/I [\(describe(context))] \(message())", ddlog: Logger.appLogger)
        } else {
            DDLogInfo("#SD/I [\(currentQueueName)] \(message())", ddlog: Logger.appLogger)
        }
    }

    static func w(_ message: @autoclosure() -> String, context: AnyObject? = nil) {
        if let context = context {
            DDLogWarn("#SD/W [\(describe(context))] \(message())", ddlog: Logger.appLogger)
        } else {
            DDLogWarn("#SD/W [\(currentQueueName)] \(message())", ddlog: Logger.appLogger)
        }
    }

    static func e(_ message: @autoclosure() -> String, context: AnyObject? = nil) {
        if let context = context {
            DDLogError("#SD/E [\(describe(context))] \(message())", ddlog: Logger.appLogger)
        } else {
            DDLogError("#SD/E [\(currentQueueName)] \(message())", ddlog: Logger.appLogger)
        }
    }
}
