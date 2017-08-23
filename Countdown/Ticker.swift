//
//  Ticker.swift
//  Countdown
//
//  Created by Hana Kim on 8/22/17.
//  Copyright © 2017 Hana Kim. All rights reserved.
//

import UIKit

class Ticker: UIView {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

    var numOfTics = 1 // how many tick marks to have
    var ticKMarks = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.backgroundColor = UIColor.red
        print(numOfTics)
        
        
        ticKMarks.backgroundColor = UIColor.blue
        ticKMarks.frame.size = CGSize(width: 20, height: 20)
//        ticMarks.frame = UIView.init(frame: <#T##CGRect#>)
        
        self.addSubview(ticKMarks)
    }
    
}
