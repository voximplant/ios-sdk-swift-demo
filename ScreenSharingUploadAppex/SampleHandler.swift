/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

import ReplayKit
import VoxImplantSDK

extension UserDefaults {
    static var main: UserDefaults {
        // App Group UserDefaults needed for communication between the app and the appex
        return UserDefaults(suiteName: "group.com.voximplant.demos")!
    }
}

extension CGImagePropertyOrientation {
    var rotation: VIRotation {
        switch self {
        case .up, .upMirrored:
            return ._0
        case .right, .rightMirrored:
            return ._270
        case .left, .leftMirrored:
            return ._90
        case .down, .downMirrored:
            return ._180
        }
    }
}

class SampleHandler: RPBroadcastSampleHandler, VICallDelegate {
    var client: VIClient
    var authService: AuthService
    var screenVideoSource = VICustomVideoSource(screenCastFormat: ())
    var screenSharingCall: VICall?
    
    @UserDefault("activecall")
    var managedCallee: String?
    
    override init() {
        let viclient = VIClient.init(delegateQueue: .main)
        self.client = viclient
        self.authService = AuthService(viclient)
        super.init()
    }
    
    private let notificationCenter = DarwinNotificationCenter()
    
    func call(_ call: VICall,
              didDisconnectWithHeaders headers: [AnyHashable : Any]?,
              answeredElsewhere: NSNumber
    ) {
        screenSharingCall?.remove(self)
        notificationCenter.sendNotification(.broadcastCallEnded)
    }
    
    func call(_ call: VICall,
              didFailWithError error: Error,
              headers: [AnyHashable : Any]?
    ) {
        screenSharingCall?.remove(self)
        notificationCenter.sendNotification(.broadcastCallEnded)
    }
    
    override func broadcastStarted(withSetupInfo setupInfo: [String : NSObject]?) {
        // User has requested to start the broadcast.
        // On iOS 11 it starts from Control Panel, on iOS 12 and above it could be started within the app (RPSystemBroadcastPickerView).
        
        Logger.configure(appName: "ScreenSharingUploadAppex")
        
        let screenVideoSource = self.screenVideoSource
       
        if authService.possibleToLogin,
           let roomid = self.managedCallee
        {
            Log.i("Logging in with token which used in the app")
            authService.loginWithAccessToken()
            { [weak self] (isError: Error?) in
                if let error = isError {
                    self?.finishBroadcast(with: BroadcastError.authError)
                    Log.i("Problem due to login: \(error)")
                } else {
                    Log.i("Login success, roomid: \(roomid)")
                    let settings = VICallSettings()
                    // It is important to use only .H264 encoding in appex.
                    settings.preferredVideoCodec = .H264
                    settings.receiveAudio = false
                    settings.videoFlags = VIVideoFlags.videoFlags(receiveVideo: false, sendVideo: true)
                    if let screenSharingCall = self?.client.callConference(roomid, settings: settings),
                        let self = self
                    {
                        self.screenSharingCall = screenSharingCall
                        screenSharingCall.videoSource = screenVideoSource
                        screenSharingCall.sendAudio = false
                        
                        screenSharingCall.add(self)
                        screenSharingCall.start()
                        
                        self.notificationCenter.registerForNotification(.callEnded)
                        self.notificationCenter.callEndedHandler = {
                            Log.i("callEnded notification received, screensharing call will hangup")
                            screenSharingCall.hangup(withHeaders: nil)
                            self.finishBroadcast(with: BroadcastError.callEnded)
                        }
                        self.notificationCenter.sendNotification(.broadcastStarted)
                        
                    } else {
                        self?.finishBroadcast(with: BroadcastError.nilOnCallInitialisation)
                        Log.i("Can't initiate a screensharing")
                    }
                }
            }
        } else {
            self.finishBroadcast(with: BroadcastError.noCall)
            Log.i("Impossible to login or no room")
        }
    }
    
    override func broadcastPaused() {
        // Empty method should be. Don't need it. Used only in BroadcastSetupUIAppex design method.
    }
    
    override func broadcastResumed() {
        // Empty method should be. Don't need it. Used only in BroadcastSetupUIAppex design method.
    }
    
    override func broadcastFinished() {
        Log.i("Broadcast finished")
        // User has requested to finish the broadcast or it interrupted by OS (with incoming call, for example).
        if let screenSharingCall = self.screenSharingCall {
            Log.i("Hangup")
            screenSharingCall.hangup(withHeaders: nil)
            self.notificationCenter.sendNotification(.broadcastEnded)
        } else {
            self.finishBroadcast(with: BroadcastError.noCall)
        }
    }
    
    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
        if sampleBufferType != .video {
            return
        }
        
        if (CMSampleBufferGetNumSamples(sampleBuffer) != 1 || !CMSampleBufferIsValid(sampleBuffer) ||
            !CMSampleBufferDataIsReady(sampleBuffer)) {
            return;
        }

        if let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            // let options = [kCVPixelBufferCGImageCompatibilityKey: true, kCVPixelBufferCGBitmapContextCompatibilityKey: true]
            
            var rotation: VIRotation?
            if let uint32rotation = CMGetAttachment(sampleBuffer, key: RPVideoSampleOrientationKey as CFString, attachmentModeOut: nil)?.uint32Value {
                rotation = CGImagePropertyOrientation(rawValue: uint32rotation)?.rotation
            }
                
            self.screenVideoSource.sendVideoFrame(pixelBuffer, rotation: rotation ?? VIRotation._0)
        }
    }
    
    private func finishBroadcast(with error: Error) {
        // This is iOS bug: sometimes finishBroadcastWithError could have no effect.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.finishBroadcastWithError(error)
        }
    }
}
