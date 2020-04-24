/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

import VoxImplantSDK

protocol AudioDeviceSelecting where Self: UIViewController { }

extension AudioDeviceSelecting {
    func showAudioDevicesActionSheet(sourceView: UIView) {
        guard let audioDevices = VIAudioManager.shared()?.availableAudioDevices() else { return }
        let currentDevice = VIAudioManager.shared()?.currentAudioDevice()
        AlertHelper.showActionSheet(
            actions: audioDevices.map { device in
                UIAlertAction(title: string(from: device, isCurrent: currentDevice?.type == device.type), style: .default) { _ in
                    VIAudioManager.shared().select(device)
                }
            },
            sourceView: sourceView,
            on: self
        )
    }
    
    private func string(from device: VIAudioDevice, isCurrent: Bool) -> String {
        let formattedString = String(describing: device).replacingOccurrences(of: "VIAudioDevice", with: "")
        return isCurrent ? "\(formattedString) (Current)" : formattedString
    }
}
