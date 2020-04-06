/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

import UIKit

struct ConferenceCallButtonModels {
    static let mute = ConferenceCallButtonModel(image: UIImage(named: "micOn"), imageSelected: UIImage(named: "micOff"), text: "Mic")
    static let chooseAudio = ConferenceCallButtonModel(image: UIImage(named: "audioDevice"), text: "Audio")
    static let switchCamera = ConferenceCallButtonModel(image: UIImage(named: "switchCam"), text: "Switch")
    static let video = ConferenceCallButtonModel(image: UIImage(named: "videoOn"), imageSelected: UIImage(named: "videoOff"), text: "Cam")
    static let exit = ConferenceCallButtonModel(image: UIImage(named: "exit"), imageTint: #colorLiteral(red: 1, green: 0.02352941176, blue: 0.2549019608, alpha: 1), text: "Leave")
}
