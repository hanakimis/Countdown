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
        self.backgroundColor = UIColor.clear
    }
    
    override func draw(_ rect: CGRect) {
        
        let containingBoxSide:CGFloat = 120.0
        
        let sliceBlue = UIColor(red: 0.129, green: 0.549, blue: 0.765, alpha: 1.000)

        
        //// General Declarations
        let context = UIGraphicsGetCurrentContext()
        
        //// Oval Drawing
        context?.saveGState()
        context?.translateBy(x: 0, y: containingBoxSide)
        context?.rotate(by: -90 * .pi / 180)
        
        let ovalRect = CGRect(x: 0, y: 0, width: containingBoxSide, height: containingBoxSide)
        let ovalPath = UIBezierPath()
        ovalPath.addArc(withCenter: CGPoint(x: ovalRect.midX, y: ovalRect.midY), radius: ovalRect.width / 2, startAngle: -360 * .pi / 180, endAngle: 0 * .pi / 180, clockwise: true)
        ovalPath.addLine(to: CGPoint(x: ovalRect.midX, y: ovalRect.midY))
        ovalPath.close()
        
        sliceBlue.setFill()
        ovalPath.fill()
        
        
        
        context?.restoreGState()

        
        
        
    }

    
}
