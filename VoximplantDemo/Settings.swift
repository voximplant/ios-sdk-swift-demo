/*
 *  Copyright (c) 2011-2018, Zingaya, Inc. All rights reserved.
 */

import Foundation
import VoxImplantSDK

class Settings: NSObject {
    fileprivate let kCallKitEnabledKey = "kCallKitEnabledKey"
    fileprivate let kUserLoginKey = "kUserLoginKey"
    fileprivate let kAccessTokenKey = "kAccessTokenKey"
    fileprivate let kRefreshTokenKey = "kRefreshTokenKey"
    fileprivate let kAccessExpireKey = "kAccessExpireKey"
    fileprivate let kRefreshExpireKey = "kRefreshExpireKey"
    fileprivate let kDisplayNameKey = "kDisplayName"
    fileprivate let kServerGatewayKey = "kServerGatewayKey"
    fileprivate let kCameraModeKey = "kCameraModeKey"
    fileprivate let kCameraMirroringKey = "kCameraMirroringKey"
    fileprivate let kSupportedOrientationKey = "kSupportedOrientationKey"
    fileprivate let kDefaultCamera = "kDefaultCamera"
    fileprivate let kPreferredCodecKey = "kVideoCodecKey"

    fileprivate let defaults = UserDefaults.standard

    static let shared = Settings()

    override init() {
        super.init()
        if !defaults.bool(forKey: "initialized") {
            cameraMirroring = true
#if targetEnvironment(simulator)
            cameraMode = .Custom
#endif
            defaults.set(true, forKey: "initialized")
            defaults.synchronize()
        }
    }

    var callKitEnabled: Bool {
        get {
            return defaults.bool(forKey: kCallKitEnabledKey)
        }
        set {
            defaults.set(newValue, forKey: kCallKitEnabledKey)
        }
    }

    var userLogin: String? {
        get {
            return defaults.string(forKey: kUserLoginKey)
        }
        set {
            defaults.set(newValue, forKey: kUserLoginKey)
        }
    }
    var accessToken: String? {
        get {
            return defaults.string(forKey: kAccessTokenKey)
        }
        set {
            defaults.set(newValue, forKey: kAccessTokenKey)
        }
    }
    var refreshToken: String? {
        get {
            return defaults.string(forKey: kRefreshTokenKey)
        }
        set {
            defaults.set(newValue, forKey: kRefreshTokenKey)
        }
    }
    var accessExpire: Date? {
        get {
            return defaults.object(forKey: kAccessExpireKey) as? Date
        }
        set {
            defaults.set(newValue, forKey: kAccessExpireKey)
        }
    }
    var refreshExpire: Date? {
        get {
            return defaults.object(forKey: kRefreshExpireKey) as? Date
        }
        set {
            defaults.set(newValue, forKey: kRefreshExpireKey)
        }
    }
    var displayName: String? {
        get {
            return defaults.string(forKey: kDisplayNameKey)
        }
        set {
            defaults.set(newValue, forKey: kDisplayNameKey)
        }
    }
    var serverGateway: String? {
        get {
            return defaults.string(forKey: kServerGatewayKey)
        }
        set {
            defaults.set(newValue, forKey: kServerGatewayKey)
        }
    }
    var cameraMode: CameraMode! {
        get {
            let mode = CameraMode(rawValue: defaults.integer(forKey: kCameraModeKey))
            return mode != nil ? mode : .Normal
        }
        set {
            defaults.set(newValue.rawValue, forKey: kCameraModeKey)
        }
    }
    var cameraMirroring: Bool {
        get {
            return defaults.bool(forKey: kCameraMirroringKey)
        }
        set {
            defaults.set(newValue, forKey: kCameraMirroringKey)
        }
    }
    var supportedOrientation: Int {
        get {
            return defaults.integer(forKey: kSupportedOrientationKey)
        }
        set {
            defaults.set(newValue, forKey: kSupportedOrientationKey)
        }
    }
    var defaultToBackCamera: Bool {
        get {
            return defaults.bool(forKey: kDefaultCamera)
        }
        set {
            defaults.set(newValue, forKey: kDefaultCamera)
        }
    }
    var preferredCodec: VIVideoCodec! {
        get {
            let codec = VIVideoCodec(rawValue: defaults.integer(forKey: kPreferredCodecKey))
            return codec != nil ? codec : .auto
        }
        set {
            defaults.set(newValue.rawValue, forKey: kPreferredCodecKey)
        }
    }
}
