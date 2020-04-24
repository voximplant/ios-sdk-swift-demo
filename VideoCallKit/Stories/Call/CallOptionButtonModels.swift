/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

import UIKit

enum CallOptionButtonModels {
    static let mute = CallOptionButtonModel(image: UIImage(named: "micOn"), imageSelected: UIImage(named: "micOff"), text: "Mic")
    static let chooseAudio = CallOptionButtonModel(image: UIImage(named: "audioDevice"), text: "Audio")
    static let hold = CallOptionButtonModel(image: UIImage(named: "hold"), text: "Hold")
    static let video = CallOptionButtonModel(image: UIImage(named: "videoOn"), imageSelected: UIImage(named: "videoOff"), text: "Cam")
    static let hangup = CallOptionButtonModel(image: UIImage(named: "hangup"), imageTint: #colorLiteral(red: 1, green: 0.02352941176, blue: 0.2549019608, alpha: 1), text: "Hangup")
}
