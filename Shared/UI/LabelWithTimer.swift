/*
 *  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
 */

import UIKit

@objc protocol TimerDelegate: AnyObject {
    func updateTime()
}

class LabelWithTimer: UILabel {
    
    @IBOutlet weak var delegate: TimerDelegate?
    private var timer: Timer?
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
    
    deinit {
        timer?.invalidate()
    }
    
    func runTimer() {
        timer = Timer.scheduledTimer(timeInterval: 1,
                                     target: self,
                                     selector: (#selector(updateTimer)),
                                     userInfo: nil,
                                     repeats: true)
    }
    
    @objc private func updateTimer() {
        delegate?.updateTime()
    }
    
    func buildStringTimeToDisplay(timeInterval: TimeInterval) -> String {
        let date = Date(timeIntervalSince1970: timeInterval)
        let formattedDate = dateFormatter.string(from: date)
        return formattedDate.starts(with: "00") ? String(formattedDate.dropFirst(3)) : formattedDate
    }
}

