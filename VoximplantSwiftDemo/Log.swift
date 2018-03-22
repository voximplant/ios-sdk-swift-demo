/*
 *  Copyright (c) 2011-2018, Zingaya, Inc. All rights reserved.
 */

import Foundation
import CocoaLumberjack

var ddLogLevel = DDLogLevel.off

class Log {
    class func enable(level: DDLogLevel!) {
        ddLogLevel = level

        if #available(iOS 10.0, *) {
            DDLog.add(DDOSLogger.sharedInstance, with: ddLogLevel)
        } else {
            DDLog.add(DDTTYLogger.sharedInstance, with: ddLogLevel)
            DDLog.add(DDASLLogger.sharedInstance, with: ddLogLevel)
        }
    }

    fileprivate class func describe(_ obj : AnyObject!) -> String {
        if (obj is String) {
            return "\(currentQueueName()!) | \(obj)"
        } else {
            return "\(currentQueueName()!) | \(String(describing: type(of: obj!))) <\(Unmanaged.passUnretained(obj).toOpaque())>"
        }
    }

    fileprivate class func currentQueueName() -> String! {
        let name = __dispatch_queue_get_label(nil)
        if let queue = String(cString: name, encoding: .utf8)?.components(separatedBy: ".").last {
            return queue.padding(toLength: 10, withPad: " ", startingAt: 0)
        }
        return "\(Unmanaged.passUnretained(Thread.current).toOpaque())".padding(toLength: 10, withPad: " ", startingAt: 0)
    }

    class func v(_ message: @autoclosure() -> String, context: AnyObject? = nil) {
        if let context = context {
            DDLogVerbose("#SD/V [\(describe(context))] \(message())")
        } else {
            DDLogVerbose("#SD/V [\(currentQueueName()!)] \(message())")
        }
    }

    class func d(_ message: @autoclosure() -> String, context: AnyObject? = nil) {
        if let context = context {
            DDLogDebug("#SD/[\(describe(context))] \(message())")
        } else {
            DDLogDebug("#SD/[\(currentQueueName()!)] \(message())")
        }
    }

    class func i(_ message: @autoclosure() -> String, context: AnyObject? = nil) {
        if let context = context {
            DDLogInfo("#SD/I [\(describe(context))] \(message())")
        } else {
            DDLogInfo("#SD/I [\(currentQueueName()!)] \(message())")
        }
    }

    class func w(_ message: @autoclosure() -> String, context: AnyObject? = nil) {
        if let context = context {
            DDLogWarn("#SD/W [\(describe(context))] \(message())")
        } else {
            DDLogWarn("#SD/W [\(currentQueueName()!)] \(message())")
        }
    }

    class func e(_ message: @autoclosure() -> String, context: AnyObject? = nil) {
        if let context = context {
            DDLogError("#SD/E [\(describe(context))] \(message())")
        } else {
            DDLogError("#SD/E [\(currentQueueName()!)] \(message())")
        }
    }
}
