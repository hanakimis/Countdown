//
//  TickMark.swift
//  Countdown
//
//  Created by Hana Kim on 8/23/17.
//  Copyright © 2017 Hana Kim. All rights reserved.
//

import UIKit


/* from https://stackoverflow.com/questions/24263007/how-to-use-hex-colour-values */

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(rgb: Int) {
        self.init(
            red: (rgb >> 16) & 0xFF,
            green: (rgb >> 8) & 0xFF,
            blue: rgb & 0xFF
        )
    }
}


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
    var tickLength: CGFloat = 16.0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        
        // figure out how to call the other initalizer function
        self.backgroundColor = UIColor.clear
        containMark.backgroundColor = UIColor(rgb: 0x2183B6)
        containMark.frame.size = CGSize(width: 1, height: tickLength)
        
        markStatus.backgroundColor = UIColor(rgb: 0x2183B6)
        markStatus.frame.size = CGSize(width: 1, height: tickLength)
        
        let midpoint = (frame.size.width - containMark.frame.width) / 2
        
        containMark.frame.origin = CGPoint(x: midpoint, y: 0.0)
        markStatus.frame.origin = CGPoint(x: midpoint, y: 0.0)
        
        self.addSubview(containMark)
        self.addSubview(markStatus)
        
        
//        init(tickLength: tickLength, tickColor: tickColor, tickBGColor: tickBGColor, frame: frame)
        
        
        
        
    }
    
    init(tickLength: CGFloat, tickColor: UIColor, tickBGColor: UIColor, frame: CGRect) {
        super.init(frame: frame)
        
        self.tickLength = tickLength
        
        self.backgroundColor = UIColor.clear
        containMark.backgroundColor = UIColor(rgb: 0x2183B6)
        containMark.alpha = 0.2
        containMark.frame.size = CGSize(width: 1.0, height: tickLength)
        
        
        markStatus.backgroundColor = UIColor(rgb: 0x2183B6)
        markStatus.frame.size = CGSize(width: 1.0, height: 0)
        
        let midpoint = (frame.size.width - containMark.frame.width) / 2
        
        containMark.frame.origin = CGPoint(x: midpoint, y: 0.0)
        markStatus.frame.origin = CGPoint(x: midpoint, y: 0.0)
        
        self.addSubview(containMark)
        self.addSubview(markStatus)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func turnOn() {
        markStatus.frame.size.height = self.tickLength
//        markStatus.frame.origin.y = 0.0
    }
    
    func turnOff() {
        self.markStatus.frame.size.height = 0.0
//        self.markStatus.frame.origin.y = tickLength
    }
    
    func animateOn() {
        UIView.animate(withDuration: 0.2) {
            self.markStatus.frame.size.height = self.tickLength
        }
    }
    
    func animateOff() {
        UIView.animate(withDuration: 0.5) {
            self.markStatus.frame.size.height = 0.0
           
        }
    }
    
}
