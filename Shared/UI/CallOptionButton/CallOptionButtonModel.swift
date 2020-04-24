/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

import UIKit

struct CallOptionButtonModel: Equatable {
    let image: UIImage?
    let imageSelected: UIImage?
    let imageTint: UIColor?
    let background: UIColor?
    let text: String
    
    init(image: UIImage?, imageSelected: UIImage? = nil, imageTint: UIColor = .white, background: UIColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.1), text: String) {
        self.image = image
        self.imageSelected = imageSelected ?? image
        self.imageTint = imageTint
        self.background = background
        self.text = text
    }
}
