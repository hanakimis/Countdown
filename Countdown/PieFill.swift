//
//  PieFill.swift
//  Countdown
//
//  Created by Hana Kim on 9/4/17.
//  Copyright © 2017 Hana Kim. All rights reserved.
//

import UIKit

class PieFill: UIView {
    
    var totalDays: CGFloat = 0.0
    var daysLeft: CGFloat = 0.0
    var fillColor = UIColor(rgb: 0x2183B6)
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = false // when overriding drawRect, you must specify this to maintain transparency.
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    func initialDaysLeft(initialDaysLeft: CGFloat) {
        // set the property for the number of segments originally
        self.totalDays = initialDaysLeft
    }
    

    func updateFill(daysLeft: CGFloat, totalDaysSet: CGFloat) {
        self.totalDays = totalDaysSet
        self.daysLeft = daysLeft
        
        self.setNeedsDisplay()
    }
    
    @objc func rotationEnd() -> CGFloat {
        var endAngle:CGFloat = 0.0
        
        if self.totalDays > 0 {
            // just make the circle nice
            if totalDays <= 7 {
                totalDays = 7
            }
            
            let percentageLeft = daysLeft/totalDays
            // the starting angle is -90 degrees (top of the circle, as the context is flipped). By default, 0 is the right hand side of the circle, with the positive angle being in an anti-clockwise direction (same as a unit circle in maths).
            let startAngle = -CGFloat.pi * 0.5

            endAngle = 2 * .pi * percentageLeft
        }
        
        return endAngle
    }
    
    
    override func draw(_ rect: CGRect) {
        
        // get current context
        let ctx = UIGraphicsGetCurrentContext()
        
        // radius is the half the frame's width or height (whichever is smallest)
        let radius = min(frame.size.width, frame.size.height) * 0.5
        
        // center of the view
        let viewCenter = CGPoint(x: bounds.size.width * 0.5, y: bounds.size.height * 0.5)
        
        // the starting angle is -90 degrees (top of the circle, as the context is flipped). By default, 0 is the right hand side of the circle, with the positive angle being in an anti-clockwise direction (same as a unit circle in maths).
        let startAngle = -CGFloat.pi * 0.5

        ctx?.setFillColor(fillColor.cgColor)
        
        
        // update the end angle of the segment
        // set a dummy size just so that we can see in the example
//        var endAngle:CGFloat = startAngle + (.pi * 0)
        var endAngle:CGFloat = startAngle
        
        
        if totalDays > 0 {
            // just make the circle nice
            if totalDays <= 7 {
                totalDays = 7
            }

            let percentageLeft = daysLeft/totalDays
            endAngle = startAngle + 2 * .pi * percentageLeft
        }
        
        // move to the center of the pie chart
        ctx?.move(to: viewCenter)
        
        // add arc from the center for each segment (anticlockwise is specified for the arc, but as the view flips the context, it will produce a clockwise arc)
        ctx?.addArc(center: viewCenter, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        
        // fill segment
        ctx?.fillPath()
    }
    

    
}


