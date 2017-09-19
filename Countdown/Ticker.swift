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
    
    
    init(numOfTicks: Int, frame:CGRect) {
        super.init(frame: CGRect(x: frame.origin.x, y: frame.origin.y, width: frame.width, height: frame.height))
        self.numOfTicks = numOfTicks
        
        let rotationStep = (Double.pi*2) / Double(self.numOfTicks)
        // initalize array of tickmarks
        let f = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)
        
        for i in 0..<numOfTicks {
            tickMarks.append(TickMark(frame:f))
            tickMarks[i].transform = CGAffineTransform(rotationAngle: CGFloat(rotationStep*Double(i)))
            self.addSubview(tickMarks[i])
        }
    }
    
    func initializeStatus(howMany: Int) {
        // status defaults
        
        for i in 0..<howMany {
            tickMarks[i].turnOn()
        }
        
        for i in howMany..<numOfTicks {
            tickMarks[i].turnOff()
        }
    }
    
    
    func updateStatus(howMany: Int) {
        
        
        initializeStatus(howMany: howMany)
//        if howMany == 0 {
//            for i in 0..<numOfTicks {
//                tickMarks[i].turnOn()
//            }
//        } else {
//            tickMarks[howMany].turnOff()
//        }
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
    
    
//    func onTap(tapGestureRecognzier: UITapGestureRecognizer) {
//        var location = tapGestureRecognzier.location(in: self)
//        
//        // Translate location so that (0, 0) is in the center of the radar chart
//        location = CGPoint(x: location.x - frame.size.width / 2, y: frame.size.height / 2 - location.y)
//        
//        var angle = Double(atan(location.x / location.y)) * 180 / M_PI
//        if location.y < 0 {
//            angle = angle + 180
//        } else if location.x < 0 {
//            angle = angle + 360
//        }
//        
//        let degreesPerIndex = 360.0 / Double(numOfTics)
//        let index = Int(round(angle / degreesPerIndex)) % numOfTics
//        
//        print(index)
//        
//    }
    
}
