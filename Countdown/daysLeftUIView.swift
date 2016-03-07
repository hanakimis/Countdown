//
//  daysLeftUIView.swift
//  Countdown
//
//  Created by Hana Kim on 3/6/16.
//  Copyright © 2016 Hana Kim. All rights reserved.
//

import UIKit

class daysLeftUIView: UIView {
    
    


    override func drawRect(rect: CGRect) {

        let dayFillRect = CGRectMake(165, 236, 45, 45)
        let dayFillPath = UIBezierPath()
        let sliceBlue = UIColor(red: 0.129, green: 0.549, blue: 0.765, alpha: 1.000)

        dayFillPath.addArcWithCenter(CGPointMake(dayFillRect.midX, dayFillRect.midY), radius: dayFillRect.width / 2, startAngle: -90 * CGFloat(M_PI)/180, endAngle: -27 * CGFloat(M_PI)/180, clockwise: true)
        dayFillPath.addLineToPoint(CGPointMake(dayFillRect.midX, dayFillRect.midY))
        dayFillPath.closePath()
        
        sliceBlue.setFill()
        dayFillPath.fill()
        sliceBlue.setStroke()
        dayFillPath.lineWidth = 2
        dayFillPath.stroke()
    }
}
