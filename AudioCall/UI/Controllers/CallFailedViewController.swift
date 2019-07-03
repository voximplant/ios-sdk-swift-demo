/*
 *  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
 */

import UIKit

class CallFailedViewController: UIViewController {
    
    @IBOutlet weak var endpointDisplayNameLabel: UILabel!
    @IBOutlet weak var failReason: UILabel!
    
    var failingReason: String?
    var endpointDisplayName: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        failReason.text = failingReason
        endpointDisplayNameLabel.text = endpointDisplayName
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        changeStatusBarStyle(to: .default)
    }
    
}
