/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

import UIKit

enum CallOptionButtonState: Equatable {
    case initial (model: CallOptionButtonModel)
    case normal
    case selected
    case unavailable
}

final class CallOptionButton: UIView, NibLoadable {
    @IBOutlet private weak var button: UIButton!
    @IBOutlet private weak var buttonDescriptionLabel: UILabel!
    
    var touchUpHandler: ((CallOptionButton) -> Void)?
    var state: CallOptionButtonState? {
        didSet {
            if state == oldValue { return }
            switch state {
            case .initial(let model):
                self.model = model
                state = .normal
            case .unavailable:
                button.setImage(oldValue == .selected ? selectedImage : normalImage, for: .disabled)
                button.backgroundColor = oldValue == .selected ? #colorLiteral(red: 1, green: 0.02352941176, blue: 0.2549019608, alpha: 1) : defaultBackground
                alpha = 0.7
                button.isEnabled = false
                button.isSelected = false
            case .normal:
                button.backgroundColor = defaultBackground
                alpha = 1
                button.isEnabled = true
                button.isSelected = false
            case .selected:
                button.backgroundColor = #colorLiteral(red: 1, green: 0.02352941176, blue: 0.2549019608, alpha: 1)
                alpha = 1
                button.isEnabled = true
                button.isSelected = true
            case .none:
                break
            }
        }
    }
    
    private var defaultBackground: UIColor?
    private var normalImage: UIImage?
    private var selectedImage: UIImage?
    private var model: CallOptionButtonModel? {
        didSet {
            if model == oldValue { return }
            if let model = model {
                normalImage = model.image
                selectedImage = model.imageSelected
                button.setImage(model.image, for: .normal)
                button.setImage(model.imageSelected, for: .selected)
                button.tintColor = model.imageTint
                defaultBackground = model.background
                button.backgroundColor = defaultBackground
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
    }
    
    @IBAction private func touchUpInside(_ sender: UIButton) {
        touchUpHandler?(self)
    }
}
