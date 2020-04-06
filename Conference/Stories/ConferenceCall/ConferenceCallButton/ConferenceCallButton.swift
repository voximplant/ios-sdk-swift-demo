/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

import UIKit

enum ConferenceCallButtonState: Equatable {
    case initial (model: ConferenceCallButtonModel)
    case normal
    case selected
    case unavailable
}

final class ConferenceCallButton: UIView, NibLoadable {
    @IBOutlet private var contentView: UIView!
    @IBOutlet private weak var button: UIButton!
    @IBOutlet private weak var buttonDescriptionLabel: UILabel!
    
    var touchUpHandler: ((ConferenceCallButton) -> Void)?
    var state: ConferenceCallButtonState? {
        didSet {
            if state == oldValue { return }
            switch state {
            case .initial(let model):
                self.model = model
                state = .normal
            case .unavailable:
                button.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.1)
                button.isEnabled = false
                button.isSelected = false
            case .normal:
                button.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.1)
                button.isEnabled = true
                button.isSelected = false
            case .selected:
                button.backgroundColor = #colorLiteral(red: 1, green: 0.02352941176, blue: 0.2549019608, alpha: 1)
                button.isEnabled = true
                button.isSelected = true
            case .none:
                break
            }
        }
    }
    
    private var model: ConferenceCallButtonModel? {
        didSet {
            if model == oldValue { return }
            if let model = model {
                button.setImage(model.image, for: .normal)
                button.setImage(model.imageSelected, for: .selected)
                button.tintColor = model.imageTint
                buttonDescriptionLabel.text = model.text
            }
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
        button.layer.cornerRadius = 4
        button.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.1)
    }
    
    @IBAction private func touchUpInside(_ sender: UIButton) {
        touchUpHandler?(self)
    }
}
