/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

import VoxImplantSDK

protocol VoximplantSDKVersionContainable { }

extension VoximplantSDKVersionContainable {
    var voximplantVersion: String { VIClient.clientVersion() }
    var webRTCVersion: String { VIClient.webrtcVersion() }
    var SDKVersion: String { "VoximplantSDK \(voximplantVersion)" }
}
