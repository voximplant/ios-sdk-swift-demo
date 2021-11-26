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
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }
    
    var string: String {
        let date = Date(timeIntervalSince1970: self)
        let formattedDate = dateFormatter.string(from: date)
        return formattedDate.starts(with: "00")
            ? String(formattedDate.dropFirst(3))
            : formattedDate
    }
}
