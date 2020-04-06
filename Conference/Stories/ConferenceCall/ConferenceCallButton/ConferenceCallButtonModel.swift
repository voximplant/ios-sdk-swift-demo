/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

import UIKit

struct ConferenceCallButtonModel: Equatable {
    let image: UIImage?
    let imageSelected: UIImage?
    let imageTint: UIColor?
    let text: String
    
    init(image: UIImage?, imageSelected: UIImage? = nil, imageTint: UIColor = .white, text: String) {
        self.image = image
        self.imageSelected = imageSelected ?? image
        self.imageTint = imageTint
        self.text = text
    }
}
