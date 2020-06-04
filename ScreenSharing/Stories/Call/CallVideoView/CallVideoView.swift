/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

import UIKit

final class CallVideoView: UIView, NibLoadable {
    @IBOutlet private weak var backgroundImage: UIImageView!
    @IBOutlet weak var streamView: UIView!

    var streamEnabled: Bool = false {
        didSet {
            streamView.isHidden = !streamEnabled
        }
    }
    
    var showImage: Bool = true {
        didSet {
            backgroundImage.isHidden = !showImage
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
    }
}
