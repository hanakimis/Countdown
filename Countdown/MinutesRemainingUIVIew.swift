//
//  MinutesRemainingUIVIew.swift
//  Countdown
//
//  Created by Hana Kim on 5/29/16.
//  Copyright © 2016 Hana Kim. All rights reserved.
//

import UIKit

class MinutesRemainingUIVIew: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.backgroundColor = UIColor.clear
        
    }
    
    
    override func draw(_ rect: CGRect) {
        let intervalWidth:CGFloat = 0.8
        let intervalHeight:CGFloat = 18.0
        let diameter:CGFloat = 216.0
        let numberOfIntervals:CGFloat = 60.0
        let intervalGap = ((diameter * CGFloat(M_PI)) / numberOfIntervals) - intervalWidth
        
        let boxOffset = intervalHeight / 2
        
        let sliceBlue = UIColor(red: 0.129, green: 0.549, blue: 0.765, alpha: 1.000)
        
        let context = UIGraphicsGetCurrentContext()
        
        //// Oval 2 Drawing
        context?.saveGState()
        context?.translateBy(x: boxOffset, y: diameter+boxOffset)
        context?.rotate(by: -90 * CGFloat(M_PI) / 180)
        
        let oval2Path = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: diameter, height: diameter))
        sliceBlue.setStroke()
        oval2Path.lineWidth = intervalHeight
        context?.saveGState()
        
        context?.setLineDash(phase: 0, lengths: [intervalWidth, intervalGap])
        oval2Path.stroke()
        
        context?.restoreGState()
        
        
    }

}
