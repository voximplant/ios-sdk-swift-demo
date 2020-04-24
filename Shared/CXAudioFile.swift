/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

import VoxImplant

protocol CallKitActivationDelegate {
    func didActivateAudioSession()
    func didDeactivateAudioSession()
}

// Delay playing only after CallKit activate audio session
class CXAudioFile: NSObject, CallKitActivationDelegate, VIAudioFileDelegate {
    fileprivate var audioFile: VIAudioFile!
    fileprivate var callKitActivated: Bool = false
    fileprivate var playAtFirstOpportunity: Bool = false
    weak var delegate: VIAudioFileDelegate?
    
    init?(url audioFileURL: URL, looped: Bool) {
        super.init()
        
        if let audioFile = VIAudioFile(url: audioFileURL, looped: looped) {
            audioFile.delegate = self
            self.audioFile = audioFile
        } else {
            return nil
        }
    }
    
    fileprivate func tryToPlay() {
        if (callKitActivated && playAtFirstOpportunity) {
            audioFile.play()
        }
    }
    
    func play() {
        playAtFirstOpportunity = true
        tryToPlay()
    }
        
    func stop() {
        playAtFirstOpportunity = false
        audioFile.stop()
    }
    
    // MARK: VIAudioFileDelegate
    
    func audioFile(_ audioFile: VIAudioFile, didStartPlaying playbackError: Error?) {
        if (playbackError != nil) {
            playAtFirstOpportunity = false
        }
        delegate?.audioFile?(audioFile, didStartPlaying: playbackError)
    }
    
    func audioFile(_ audioFile: VIAudioFile?, didStopPlaying playbackError: Error?) {
        playAtFirstOpportunity = false
        delegate?.audioFile?(audioFile, didStopPlaying: playbackError)
    }
    
    // MARK: CallKitActivationDelegate
    
    func didActivateAudioSession() {
        callKitActivated = true
        tryToPlay()
    }
    
    func didDeactivateAudioSession() {
        callKitActivated = false
    }
}
