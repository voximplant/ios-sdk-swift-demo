/*
 *  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
 */

import CallKit

extension CXProvider {
    func commitTransactions(_ delegate: CXProviderDelegate) {
        for transaction in self.pendingTransactions {
            for action in transaction.actions {
                Log.i("CXProvider: \(action)")
                if let startAction = action as? CXStartCallAction {
                    delegate.provider?(self, perform: startAction)
                } else if let answerAction = action as? CXAnswerCallAction {
                    delegate.provider?(self, perform: answerAction)
                } else if let endAction = action as? CXEndCallAction {
                    delegate.provider?(self, perform: endAction)
                } else if let heldAction = action as? CXSetHeldCallAction {
                    delegate.provider?(self, perform: heldAction)
                } else if let muteAction = action as? CXSetMutedCallAction {
                    delegate.provider?(self, perform: muteAction)
                } else if let groupAction = action as? CXSetGroupCallAction {
                    delegate.provider?(self, perform: groupAction)
                } else if let dtmfAction = action as? CXPlayDTMFCallAction {
                    delegate.provider?(self, perform: dtmfAction)
                } else {
                    Log.e("Can't apply pendingTransacton \(action) of unknown type: \(type(of: action))")
                }
            }
        }
    }
}
