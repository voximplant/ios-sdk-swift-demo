/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

import UIKit

fileprivate enum Edge {
    case topLeft
    case topRight
    case bottomRight
    case bottomLeft
}

final class EdgeMagneticView: UIView {
    @IBOutlet private weak var innerView: UIView! // must be attached as a subview
    private var currentEdge: Edge = .topRight
    
    override func layoutSubviews() {
        super.layoutSubviews()
        remagnete()
    }
    
    func remagnete() {
        let center = calculateCenter(
            for: currentEdge,
            within: frame.size,
            objectSize: innerView.frame.size
        )
        
        UIViewPropertyAnimator(duration: 0.1, curve: .easeInOut) {
            self.innerView.center = center
        }.startAnimation()
    }
    
    func rearrangeInnerView() {
        let edge = calculateClosestEdge(
            of: innerView.frame.origin,
            within: frame.size
        )
        
        let center = calculateCenter(
            for: edge,
            within: frame.size,
            objectSize: innerView.frame.size
        )
        
        UIViewPropertyAnimator(duration: 0.1, curve: .easeInOut) {
            self.innerView.center = center
        }.startAnimation()
        
        currentEdge = edge
    }
    
    
    private func calculateCenter(
        for edge: Edge,
        within outerSize: CGSize,
        objectSize innerSize: CGSize
    ) -> CGPoint {
        let outHeight = outerSize.height
        let outWidth = outerSize.width
        // by 2 because center needed
        let inHeight = innerSize.height / 2
        let inWidth = innerSize.width / 2
        let space: CGFloat = 4 // defaultSpacing
        
        switch edge {
        case .topLeft:
            return CGPoint(x: space + inWidth, y: space + inHeight)
        case .topRight:
            return CGPoint(x: outWidth - inWidth - space, y: space + inHeight)
        case .bottomRight:
            return CGPoint(x: outWidth - inWidth - space, y: outHeight - inHeight - space)
        case .bottomLeft:
            return CGPoint(x: space + inWidth, y: outHeight - inHeight - space)
        }
    }
    
    private func calculateClosestEdge(of origin: CGPoint, within size: CGSize) -> Edge {
        let x = origin.x
        let y = origin.y
        let height = size.height
        let width = size.width
        
        if x < width / 2 {
            return y < height / 2 ? .topLeft : .bottomLeft
        } else {
            return y < height / 2 ? .topRight : .bottomRight
        }
    }
}
