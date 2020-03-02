/*
 *  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
 */

import Foundation
import VoxImplantSDK

class LoudAudioFile: NSObject, VIAudioFileDelegate {
    fileprivate var audioFile: VIAudioFile!
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
    
    func configureAudioBeforePlaying() {
        let audioManager: VIAudioManager = VIAudioManager.shared()
        
        if (audioManager.currentAudioDevice() == VIAudioDevice(type: .receiver)) {
            audioManager.select(VIAudioDevice(type: .speaker))
        }
    }
    
    func deconfigureAudioAfterPlaying() {
        let audioManager: VIAudioManager = VIAudioManager.shared()
        
        if (audioManager.currentAudioDevice() == VIAudioDevice(type: .speaker)) {
            audioManager.select(VIAudioDevice(type: .receiver))
        }
    }
    
    func play() {
        audioFile.play()
    }
    
    func stop() {
        audioFile.stop()
    }

    // MARK: VIAudioFileDelegate
    
    func audioFile(_ audioFile: VIAudioFile?, didStopPlaying playbackError: Error?) {
        deconfigureAudioAfterPlaying()
        delegate?.audioFile?(audioFile, didStopPlaying: playbackError)
    }

    func audioFile(_ audioFile: VIAudioFile, didStartPlaying playbackError: Error?) {
        delegate?.audioFile?(audioFile, didStartPlaying: playbackError)
    }
}
