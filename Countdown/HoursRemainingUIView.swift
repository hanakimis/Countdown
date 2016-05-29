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
        let sliceBlue = UIColor(red: 0.129, green: 0.549, blue: 0.765, alpha: 1.000)
        
        //// General Declarations
        let context = UIGraphicsGetCurrentContext()
        
        //// Oval 2 Drawing
        CGContextSaveGState(context)        
        CGContextTranslateCTM(context, 0, 240)
        CGContextRotateCTM(context, -90 * CGFloat(M_PI) / 180)
        
        let oval2Path = UIBezierPath(ovalInRect: CGRectMake(0, 0, 240, 240))
        sliceBlue.setStroke()
        oval2Path.lineWidth = 48
        CGContextSaveGState(context)
        
        let distance = 5 * CGFloat(M_PI)
        
        CGContextSetLineDash(context, 0, [2, distance], 2)
        oval2Path.stroke()

        CGContextRestoreGState(context)

        
    }
    
}
