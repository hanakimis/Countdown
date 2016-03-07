//
//  TimerV01.swift
//  timer
//
//  Created by Hana Kim on 12/6/15.
//  Copyright (c) 2015 Hana Inc.. All rights reserved.
//
//  Generated by PaintCode (www.paintcodeapp.com)
//



import UIKit

public class TimerV01 : NSObject {
    
    //// Drawing Methods
    
    public class func drawTimer() {
        //// General Declarations
        let context = UIGraphicsGetCurrentContext()
        
        //// Color Declarations
        let sliceBlue = UIColor(red: 0.129, green: 0.549, blue: 0.765, alpha: 1.000)
        let backgroundColor = UIColor(red: 0.149, green: 0.169, blue: 0.192, alpha: 1.000)
        
        //// Rectangle Drawing
        let rectanglePath = UIBezierPath(rect: CGRectMake(0, 0, 375, 667))
        backgroundColor.setFill()
        rectanglePath.fill()
        
        
        //// seconds Drawing
        let secondsRect = CGRectMake(125, 195, 126, 126)
        let secondsPath = UIBezierPath()
        secondsPath.addArcWithCenter(CGPointMake(secondsRect.midX, secondsRect.midY), radius: secondsRect.width / 2, startAngle: -90 * CGFloat(M_PI)/180, endAngle: 270 * CGFloat(M_PI)/180, clockwise: true)
        
        sliceBlue.setStroke()
        secondsPath.lineWidth = 7.75
        CGContextSaveGState(context)
        CGContextSetLineDash(context, 0, [0.5, 5.5], 2)
        secondsPath.stroke()
        CGContextRestoreGState(context)
        
        
        //// minutes Drawing
        let minutesRect = CGRectMake(139, 209, 98, 98)
        let minutesPath = UIBezierPath()
        minutesPath.addArcWithCenter(CGPointMake(minutesRect.midX, minutesRect.midY), radius: minutesRect.width / 2, startAngle: -90 * CGFloat(M_PI)/180, endAngle: 270 * CGFloat(M_PI)/180, clockwise: true)
        
        sliceBlue.setStroke()
        minutesPath.lineWidth = 12
        CGContextSaveGState(context)
        CGContextSetLineDash(context, 0, [0.5, 5.5], 2)
        minutesPath.stroke()
        CGContextRestoreGState(context)
        
        
        //// hours Drawing
        let hoursRect = CGRectMake(154, 225, 67, 67)
        let hoursPath = UIBezierPath()
        hoursPath.addArcWithCenter(CGPointMake(hoursRect.midX, hoursRect.midY), radius: hoursRect.width / 2, startAngle: -90 * CGFloat(M_PI)/180, endAngle: 270 * CGFloat(M_PI)/180, clockwise: true)
        
        sliceBlue.setStroke()
        hoursPath.lineWidth = 12
        CGContextSaveGState(context)
        CGContextSetLineDash(context, 0, [0.75, 5.25], 2)
        hoursPath.stroke()
        CGContextRestoreGState(context)
        
        
        //// day fill Drawing
        let dayFillRect = CGRectMake(165, 236, 45, 45)
        let dayFillPath = UIBezierPath()
        dayFillPath.addArcWithCenter(CGPointMake(dayFillRect.midX, dayFillRect.midY), radius: dayFillRect.width / 2, startAngle: -180 * CGFloat(M_PI)/180, endAngle: -70 * CGFloat(M_PI)/180, clockwise: true)
        dayFillPath.addLineToPoint(CGPointMake(dayFillRect.midX, dayFillRect.midY))
        dayFillPath.closePath()
        
        sliceBlue.setFill()
        dayFillPath.fill()
        sliceBlue.setStroke()
        dayFillPath.lineWidth = 2
        dayFillPath.stroke()
    }
}