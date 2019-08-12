/*
 *  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
 */

import UIKit

@objc protocol KeyPadDelegate: class {
    
    func DTMFButtonTouched(symbol: String)
    
    func keypadDidHide()
}

class KeyPadView: UIView {
    
    @IBOutlet var numberButtons: [UIButton]!
    
    @IBOutlet weak var delegate: KeyPadDelegate?
    
    var nibName: String {
        return String(describing: type(of: self))
    }
    
    var contentView: UIView?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        guard let view = loadViewFromNib() else { return nil }
        
        view.frame = self.bounds
        self.addSubview(view)
        contentView = view
    }
    
    func loadViewFromNib() -> UIView? {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: nibName, bundle: bundle)
        
        return nib.instantiate(withOwner: self, options: nil).first as? UIView
    }
    
    // MARK: Actions
    @IBAction func numberTouch(_ sender: UIButton) {
        guard let symbolSentFromDTMF = sender.currentTitle else { return }
        
        delegate?.DTMFButtonTouched(symbol: symbolSentFromDTMF)
    }
    
    @IBAction func hideTouch(_ sender: UIButton) {
        self.isHidden = true
        
        delegate?.keypadDidHide()
    }
    
}
