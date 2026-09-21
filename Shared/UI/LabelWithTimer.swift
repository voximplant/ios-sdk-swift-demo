/*
 *  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
 */

import UIKit

final class LabelWithTimer: UILabel {
    private var timer: Timer?
    
    var additionalText: String?
    
    deinit {
        stopTimer()
    }
    
    func runTimer(with dataSource: @autoclosure @escaping () -> TimeInterval) {
        if timer != nil { return }
        timer = Timer.scheduledTimer(
            withTimeInterval: 1,
            repeats: true,
            block: { [weak self] _ in
                self?.text = "\(dataSource().string)\(self?.additionalText ?? "")"
            }
        )
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

fileprivate extension TimeInterval {
    var string: String {
        let totalSeconds = Int(self)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds / 60) % 60
        let seconds = totalSeconds % 60
        
        return hours > 0
            ? String(format: "%02d:%02d:%02d", hours, minutes, seconds)
            : String(format: "%02d:%02d", minutes, seconds)
    }
}
