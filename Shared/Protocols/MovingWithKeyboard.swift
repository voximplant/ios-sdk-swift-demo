/*
 *  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
 */

import UIKit

protocol MovingWithKeyboard where Self: UIView {
    var keyboardWillChangeFrameObserver: NSObjectProtocol? { get set }
    var keyboardWillHideObserver: NSObjectProtocol? { get set }
    func keyboardWillHide()
    func keyboardWillChange(heightOfKeyboard: CGFloat)
}

extension MovingWithKeyboard {
    func subscribeOnKeyboardEvents() {
        keyboardWillChangeFrameObserver = NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: OperationQueue.main
        ) { [weak self] notification in
            guard let self = self,
                  let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue
            else { return }
            self.keyboardWillChange(heightOfKeyboard: keyboardValue.cgRectValue.height)
        }
        
        keyboardWillHideObserver = NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: OperationQueue.main
        ) { [weak self] notification in
            if let self = self {
                self.keyboardWillHide()
            }
        }
    }
    
    func unsubscribeFromKeyboardEvents() {
        if let changeFrameObserver = keyboardWillChangeFrameObserver {
            NotificationCenter.default.removeObserver(changeFrameObserver)
        }
        if let willHideObserver = keyboardWillHideObserver {
            NotificationCenter.default.removeObserver(willHideObserver)
        }
    }
}
