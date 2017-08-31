//
//  TickMark.swift
//  Countdown
//
//  Created by Hana Kim on 8/23/17.
//  Copyright © 2017 Hana Kim. All rights reserved.
//

import UIKit

class TickMark: UIView {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

    var containMark = UIView()
    var markStatus = UIView()
    
    var status = false
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.clear
        containMark.backgroundColor = UIColor.black
        containMark.frame.size = CGSize(width: 2, height: 16)
        
        markStatus.backgroundColor = UIColor.blue
        markStatus.frame.size = CGSize(width: 2, height: 16)
        
        
        let midpoint = (frame.size.width - containMark.frame.width) / 2
        
        
        containMark.frame.origin = CGPoint(x: midpoint, y: 0.0)
        markStatus.frame.origin = CGPoint(x: midpoint, y: 0.0)
        markStatus.alpha = 0.0
        
        self.addSubview(containMark)
        self.addSubview(markStatus)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func turnOn() {
        markStatus.alpha = 1.0
    }
    
    func turnOff() {
        markStatus.alpha = 0.0
    }
    
}
