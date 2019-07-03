/*
 *  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
 */

import UIKit

@objc protocol TimerDelegate: class {
    func updateTime()
}

class LabelWithTimer: UILabel {
    
    @IBOutlet weak var delegate: TimerDelegate?
    private var timer: Timer?
    
    deinit {
        timer?.invalidate()
    }
    
    open func runTimer() {
        timer = Timer.scheduledTimer(timeInterval: 1,
                                     target: self,
                                     selector: (#selector(updateTimer)),
                                     userInfo: nil,
                                     repeats: true)
    }
    
    @objc private func updateTimer() {
        delegate?.updateTime()
    }
}

