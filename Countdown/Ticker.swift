//
//  Ticker.swift
//  Countdown
//
//  Created by Hana Kim on 8/22/17.
//  Copyright © 2017 Hana Kim. All rights reserved.
//

import UIKit

extension CGRect {
    init(center: CGPoint, radius: CGFloat) {
        let origin = CGPoint(x: center.x - radius, y: center.y - radius)
        let size = CGSize(width: radius * 2, height: radius * 2)
        self.init(origin: origin, size: size)
    }
    
    init(center: CGPoint, width: CGFloat, height: CGFloat) {
        let origin = CGPoint(x: center.x - width/2, y: center.y - height/2)
        let size = CGSize(width: width, height: height)
        self.init(origin: origin, size: size)
    }
}


class Ticker: UIView {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

    var tickMarks = [TickMark]() // should be an array
    var numOfTicks = 1 // how many tick marks to have
    var status = 0 // how many tick marks should be "on"; defaults to none
    
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    
    init(numOfTicks: Int, tickLength: CGFloat, frame:CGRect) {
        super.init(frame: CGRect(x: frame.origin.x, y: frame.origin.y, width: frame.width, height: frame.height))
        self.numOfTicks = numOfTicks
        
        let rotationStep = (Double.pi*2) / Double(self.numOfTicks)

        let f = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)
        
        let tColor = UIColor(rgb: 0x2183B6)
        let tBGColor = UIColor.black
        
        for i in 0..<numOfTicks {
            tickMarks.append(TickMark(tickLength: tickLength, tickColor: tColor, tickBGColor: tBGColor, frame: f))
            tickMarks[i].transform = CGAffineTransform(rotationAngle: CGFloat(rotationStep*Double(i)))
            self.addSubview(tickMarks[i])
        }
    }
    
    func resetTickMarks() {
        for i in 0..<numOfTicks {
            tickMarks[i].turnOff()
        }
    }
    
    func initializeStatus(howMany: Int) {
        
        status = howMany
        
        for i in 0..<howMany {
            tickMarks[i].turnOn()
        }
        
        for i in howMany..<numOfTicks {
            tickMarks[i].turnOff()
        }
    }
    
    
    // update the status of the current ticker to show only this many ON
    func updateStatus(howMany: Int) {
        
        status = howMany
        
        if howMany == numOfTicks {
            for i in 0..<numOfTicks {
                tickMarks[i].turnOn()
            }
        } else {
            tickMarks[howMany].turnOff()
        }
        
    }
    
    
    func setTickMark(whichMark: Int, state: Bool) {
        state ? tickMarks[whichMark].turnOn() : tickMarks[whichMark].turnOff()
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    // use this to get location
    func radialPoint(_ degree: CGFloat) -> CGPoint {
        // get the center of the current view
        // move the view so that the origin is
        
        
        
        // this needs to be updated
        return self.center
    }
    
    
}
