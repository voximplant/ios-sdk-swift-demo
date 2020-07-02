/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

import Foundation

enum Notification: String {
    case broadcastStarted = "broadcastStarted"
    case broadcastEnded = "broadcastEnded"
    case broadcastCallEnded = "broadcastCallEnded"
    case callEnded = "callEnded"
}

final class DarwinNotificationCenter {
    private var observer: UnsafeRawPointer {
        UnsafeRawPointer(Unmanaged.passUnretained(self).toOpaque())
    }
    
    var broadcastEndedHandler: (() -> Void)?
    var broadcastStartedHandler: (() -> Void)?
    var broadcastCallEndedHandler: (() -> Void)?
    var callEndedHandler: (() -> Void)?
    
    func sendNotification(_ notification: Notification) {
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName(rawValue: notification.rawValue as CFString),
            nil, nil, true
        )
    }
    
    func registerForNotification(_ notification: Notification) {
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            observer,
            { _, observer, name, _, _ in
                if let observer = observer, let name = name {
                    let mySelf = Unmanaged<DarwinNotificationCenter>
                        .fromOpaque(observer).takeUnretainedValue()
                    mySelf.didReceiveNotification(name.rawValue as String)
                }
            },
            notification.rawValue as CFString, nil, .deliverImmediately
        )
    }
    
    func unregisterFromNotification(_ notification: Notification) {
        CFNotificationCenterRemoveObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            observer,
            CFNotificationName(rawValue: notification.rawValue as CFString),
            nil
        )
    }
    
    private func didReceiveNotification(_ name: String) {
        Log.i("DarwinNotificationCenter received notification \(name)")
        let notification = Notification(rawValue: name)
        switch notification {
        case .broadcastEnded:
            broadcastEndedHandler?()
        case .broadcastCallEnded:
            broadcastCallEndedHandler?()
        case .callEnded:
            callEndedHandler?()
        case .broadcastStarted:
            broadcastStartedHandler?()
        case .none:
            break
        }
    }
}
