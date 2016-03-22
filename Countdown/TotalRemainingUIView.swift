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
        self.backgroundColor = UIColor.redColor()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func drawRect(rect: CGRect) {
        let sliceBlue = UIColor(red: 0.129, green: 0.549, blue: 0.765, alpha: 1.000)

        let dayFillRect = CGRectMake(0, 0, frame.size.height, frame.size.width)
        
        let angle:CGFloat = 390.0
        
        let dayFillPath = UIBezierPath()
        dayFillPath.addArcWithCenter(CGPointMake(dayFillRect.midX, dayFillRect.midY), radius: dayFillRect.width / 2, startAngle: -90 * CGFloat(M_PI)/180, endAngle: -angle * CGFloat(M_PI)/180, clockwise: true)
        dayFillPath.addLineToPoint(CGPointMake(dayFillRect.midX, dayFillRect.midY))
        dayFillPath.closePath()
        
        sliceBlue.setFill()
        dayFillPath.fill()
        sliceBlue.setStroke()
        dayFillPath.lineWidth = 2
        dayFillPath.stroke()
    }

    
}
