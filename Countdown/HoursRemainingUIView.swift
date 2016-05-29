//
//  HoursRemainingUIView.swift
//  Countdown
//
//  Created by Hana Kim on 5/29/16.
//  Copyright © 2016 Hana Kim. All rights reserved.
//

import UIKit

@IBDesignable
class HoursRemainingUIView: UIView {

    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.backgroundColor = UIColor.clearColor()

    }
    
    
    override func drawRect(rect: CGRect) {
        let intervalWidth:CGFloat = 1.0
        let intervalHeight:CGFloat = 24.0
        let diameter:CGFloat = 156.0
        let numberOfIntervals:CGFloat = 24.0
        let intervalGap = ((diameter * CGFloat(M_PI)) / numberOfIntervals) - intervalWidth
        
        let boxOffset = intervalHeight / 2
        
        let sliceBlue = UIColor(red: 0.129, green: 0.549, blue: 0.765, alpha: 1.000)
        
        let context = UIGraphicsGetCurrentContext()
        
        //// Oval 2 Drawing
        CGContextSaveGState(context)
        CGContextTranslateCTM(context, boxOffset, diameter+boxOffset)
        CGContextRotateCTM(context, -90 * CGFloat(M_PI) / 180)
        
        let oval2Path = UIBezierPath(ovalInRect: CGRectMake(0, 0, diameter, diameter))
        sliceBlue.setStroke()
        oval2Path.lineWidth = intervalHeight
        CGContextSaveGState(context)
        
        
        CGContextSetLineDash(context, 0, [intervalWidth, intervalGap], 2)
        oval2Path.stroke()

        CGContextRestoreGState(context)

        
    }
    
}
