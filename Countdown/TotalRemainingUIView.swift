//
//  TotalRemainingUIView.swift
//  Countdown
//
//  Created by Hana Kim on 3/7/16.
//  Copyright © 2016 Hana Kim. All rights reserved.
//

import UIKit

@IBDesignable
class TotalRemainingUIView: UIView {

    
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.backgroundColor = UIColor.clearColor()
    }
    
    override func drawRect(rect: CGRect) {
        let sliceBlue = UIColor(red: 0.129, green: 0.549, blue: 0.765, alpha: 1.000)
//        let dayFillRect = CGRectMake(0, 0, frame.size.height, frame.size.width)
//        
//        
//        
//        print("frame height = \(frame.size.height)")
//        print("frame width = \(frame.size.width)")
//        
//        
//        let angle:CGFloat = 0.0
//        
        
        //// General Declarations
        let context = UIGraphicsGetCurrentContext()
        
        //// Oval Drawing
        CGContextSaveGState(context)
        CGContextTranslateCTM(context, 0, 274)
        CGContextRotateCTM(context, -90 * CGFloat(M_PI) / 180)
        
        let ovalRect = CGRectMake(0, 0, 274, 274)
        let ovalPath = UIBezierPath()
        ovalPath.addArcWithCenter(CGPointMake(ovalRect.midX, ovalRect.midY), radius: ovalRect.width / 2, startAngle: -360 * CGFloat(M_PI)/180, endAngle: 0 * CGFloat(M_PI)/180, clockwise: true)
        ovalPath.addLineToPoint(CGPointMake(ovalRect.midX, ovalRect.midY))
        ovalPath.closePath()
        
        sliceBlue.setFill()
        ovalPath.fill()
        
        
        
        CGContextRestoreGState(context)

        
        
        
    }

    
}
