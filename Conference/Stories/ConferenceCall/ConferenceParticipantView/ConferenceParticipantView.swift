/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

import UIKit

final class ConferenceParticipantView: UIView, NibLoadable {
    @IBOutlet private weak var labelContainer: UIView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var backgroundImage: UIImageView!
    @IBOutlet weak var streamView: UIView!

    var streamEnabled: Bool = false {
        didSet {
            streamView.isHidden = !streamEnabled
        }
    }

    var name: String? {
        get { nameLabel.text }
        set {
            labelContainer.isHidden = newValue == nil || newValue == ""
            nameLabel.text = newValue
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        sharedInit()
    }
    
    private func sharedInit() {
        setupFromNib()
        streamView.clipsToBounds = true
        backgroundImage.layer.cornerRadius = 4
        streamView.layer.cornerRadius = 4
        labelContainer.layer.cornerRadius = 4
    }
}
