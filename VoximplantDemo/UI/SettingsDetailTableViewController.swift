/*
 *  Copyright (c) 2011-2018, Zingaya, Inc. All rights reserved.
 */

import UIKit
import VoxImplantSDK

class SettingsDetailTableViewController: UITableViewController {
    var optionDescriptor: Dictionary<String, Any> = [:]
    var optionValues: [Dictionary<String, Any>] = [[:]]

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = optionDescriptor["title"] as? String
        self.optionValues = optionDescriptor["options"] as! [Dictionary<String, Any>]
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.optionValues.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "detail-option-cell", for: indexPath)
        let option = self.optionValues[indexPath.row]

        cell.textLabel?.text = option["title"] as? String

        cell.textLabel?.font = Theme.defaultFont
        cell.textLabel?.textColor = Theme.headerColor
        cell.tintColor = Theme.color

        if let settingsOption = SettingsOption(rawValue: self.optionDescriptor["id"] as! String) {
            switch settingsOption {
            case .CallManagerOption:
                cell.accessoryType = (option["value"] as! Bool) == AppDelegate.instance().callKit ? .checkmark : .none
                break
            case .OrientationOption:
                let orientation = UIDevice.current.userInterfaceIdiom == .phone ?
                        VICameraManager.shared().iPhoneOrientationMask : VICameraManager.shared().iPadOrientationMask
                cell.accessoryType = orientation.contains(VISupportedDeviceOrientation(rawValue: option["value"] as! Int)) ? .checkmark : .none
                break
            case .CurrentCameraOption:
                cell.accessoryType = (option["value"] as! Bool) == VICameraManager.shared().useBackCamera ? .checkmark : .none
                break
            case .CameraMirroringOption:
                cell.accessoryType = (option["value"] as! Bool) == VICameraManager.shared().shouldMirrorFrontCamera ? .checkmark : .none
                break
            case .CameraModeOption:
                cell.accessoryType = CameraMode(rawValue: option["value"] as! Int) == AppDelegate.instance().cameraMode ? .checkmark : .none
                break
            case .PreferredCodecOption:
                cell.accessoryType = VIVideoCodec(rawValue: option["value"] as! Int) == AppDelegate.instance().preferredCodec ? .checkmark : .none
            }
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let option = self.optionValues[indexPath.row]

        if let settingOptions = SettingsOption(rawValue: self.optionDescriptor["id"] as! String) {
            switch settingOptions {
            case .CallManagerOption:
                var enable = false
                if #available(iOS 10.0, *) {
                    enable = option["value"] as! Bool
                } else {
                    UIHelper.ShowError(error: "CallKit available on iOS 10.0 and later", action: nil)
                }

#if targetEnvironment(simulator)
                enable = false
                UIHelper.ShowError(error: "CallKit not available in the Simulator", action: nil)
#endif

                Settings.shared.callKitEnabled = enable
                AppDelegate.instance().callKit = enable
                break
            case .OrientationOption:
                var orientation = UIDevice.current.userInterfaceIdiom == .phone ?
                        VICameraManager.shared().iPhoneOrientationMask : VICameraManager.shared().iPadOrientationMask
                orientation.formSymmetricDifference(VISupportedDeviceOrientation(rawValue: option["value"] as! Int))

                Settings.shared.supportedOrientation = orientation.rawValue
                VICameraManager.shared().setSupportedDeviceOrientation(iPhone: orientation, iPad: orientation)
                break
            case .CurrentCameraOption:
                Settings.shared.defaultToBackCamera = option["value"] as! Bool
                VICameraManager.shared().useBackCamera = option["value"] as! Bool
                break
            case .CameraMirroringOption:
                Settings.shared.cameraMirroring = option["value"] as! Bool
                VICameraManager.shared().shouldMirrorFrontCamera = option["value"] as! Bool
                break
            case .CameraModeOption:
#if targetEnvironment(simulator)
            UIHelper.ShowError(error: "Only Custom camera is available in the Simulator", action: nil)
#else
                Settings.shared.cameraMode = CameraMode(rawValue: option["value"] as! Int)
                AppDelegate.instance().cameraMode = CameraMode(rawValue: option["value"] as! Int)
#endif
                break
            case .PreferredCodecOption:
                Settings.shared.preferredCodec = VIVideoCodec(rawValue: option["value"] as! Int)
                AppDelegate.instance().preferredCodec = VIVideoCodec(rawValue: option["value"] as! Int)
            }
        }

        tableView.reloadData()
    }
}
