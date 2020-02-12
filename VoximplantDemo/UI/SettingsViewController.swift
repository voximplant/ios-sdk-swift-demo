/*
 *  Copyright (c) 2011-2018, Zingaya, Inc. All rights reserved.
 */

import UIKit
import VoxImplantSDK

enum SettingsOption: String, RawRepresentable {
    case CallManagerOption, OrientationOption, CurrentCameraOption, CameraMirroringOption, CameraModeOption, PreferredCodecOption
}

enum CameraMode: Int {
    case Normal = 1, Preprocessing = 2, Custom = 3
}

extension VISupportedDeviceOrientation: Hashable {
    public var hashValue: Int {
        return self.rawValue.hashValue;
    }

    public var description: String {
        if (self == .all) {
            return "All"
        }

        var result: Array<String> = []
        if (self.contains(.portrait)) {
            result.append("Portrait")
        }
        if (self.contains(.portraitUpsideDown)) {
            result.append("Upside Down")
        }
        if (self.contains(.landscapeLeft)) {
            result.append("Landscape Left")
        }
        if (self.contains(.landscapeRight)) {
            result.append("Landscape Right")
        }

        return result.joined(separator: ", ");
    }
}

class SettingsViewController: UITableViewController {
    var selectedOption: Dictionary<String, Any> = [:]

    public var options: [Dictionary<String, Any>] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        if let settings = NSArray(contentsOfFile: Bundle.main.path(forResource: "Settings", ofType: "plist")!) {
            self.options = settings as! [Dictionary<String, Any>]
        }
        view.backgroundColor = .white
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.tableView.reloadData()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1;
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.options.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "options-table-cell", for: indexPath) as! SettingTableViewCell

        let optionDescriptor = self.options[indexPath.row]
        let optionValues = optionDescriptor["options"] as! [Dictionary<String, Any>]

        cell.titleLabel?.text = optionDescriptor["title"] as? String
        if let settingsOption = SettingsOption(rawValue: optionDescriptor["id"] as! String) {
            switch settingsOption {
            case .CallManagerOption:
                for (_, option) in optionValues.enumerated() {
                    if (option["value"] as! Bool) == AppDelegate.instance().callKit {
                        cell.valueLabel?.text = option["title"] as? String
                    }
                }
                break
            case .OrientationOption:
                let orientation = UIDevice.current.userInterfaceIdiom == .phone ?
                        VICameraManager.shared().iPhoneOrientationMask : VICameraManager.shared().iPadOrientationMask
                cell.valueLabel?.text = orientation.description
                break
            case .CurrentCameraOption:
                for (_, option) in optionValues.enumerated() {
                    if (option["value"] as! Bool) == VICameraManager.shared().useBackCamera {
                        cell.valueLabel?.text = option["title"] as? String
                    }
                }
                break;
            case .CameraMirroringOption:
                for (_, option) in optionValues.enumerated() {
                    if (option["value"] as! Bool) == VICameraManager.shared().shouldMirrorFrontCamera {
                        cell.valueLabel?.text = option["title"] as? String
                    }
                }
                break
            case .CameraModeOption:
                for (_, option) in optionValues.enumerated() {
                    if option["value"] as! Int == AppDelegate.instance().cameraMode.rawValue {
                        cell.valueLabel?.text = option["title"] as? String
                    }
                }
                break
            case .PreferredCodecOption:
                for (_, option) in optionValues.enumerated() {
                    if option["value"] as! Int == AppDelegate.instance().preferredCodec.rawValue {
                        cell.valueLabel?.text = option["title"] as? String
                    }
                }
            }
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedOption = self.options[indexPath.row]
        self.performSegue(withIdentifier: "SettingsDetails", sender: self)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let detailViewController = segue.destination as! SettingsDetailTableViewController
        detailViewController.optionDescriptor = self.selectedOption
    }
}
