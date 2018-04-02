//
//  ConcentricCirclesViewController.swift
//  Countdown
//
//  Created by Hana Kim on 8/24/17.
//  Copyright © 2017 Hana Kim. All rights reserved.
//

import UIKit

class ConcentricCirclesViewController: UIViewController {

    @IBOutlet weak var circlesContainerView: UIView!
    
    
    // labels for help
    @IBOutlet weak var topLabel: UILabel!
    @IBOutlet weak var topMiddleLabel: UILabel!
    @IBOutlet weak var bottomMiddleLabel: UILabel!
    @IBOutlet weak var bottomLabel: UILabel!
    
    @IBOutlet weak var datePicker: UIDatePicker!
    
    
    let formatter = DateFormatter()
    let defaults = UserDefaults.standard
    var countdownDate: Date!
    var today = Date()
    
    var hours = Ticker()
    var minutes = Ticker()
    var seconds = Ticker()
    
    
    var daysLeft: Int!
    var hoursLeft: Int!
    var minutesLeft: Int!
    var secondsLeft: Int!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setup the date style
        formatter.dateStyle = .medium
        
        // update if a date has been stored
        // need to do a check to see if the date is before today
        if let myDate = defaults.object(forKey: "date") {
            countdownDate = myDate as! Date
            //            datePicker.date = countdownDate
        } else {
            
            // this means date hasn't been set
            // we need to be able to take a date a couple days in advance
            
            countdownDate = Calendar.current.date(byAdding: .day, value: 1, to: today)!
            
            
        }
        
        

        let components = (Calendar.current as NSCalendar).components([.second, .minute, .hour, .day], from: today,
                                                                     to: countdownDate, options: [])
        

        daysLeft = components.day
        hoursLeft = components.hour
        minutesLeft = components.minute
        secondsLeft = components.second
        
        
    
        let minutesSize = circlesContainerView.frame.width * 0.8
        let hoursSize = circlesContainerView.frame.width * 0.6

        let minutesRect = CGRect(center: circlesContainerView.center, width: minutesSize, height: minutesSize)
        let hoursRect = CGRect(center: circlesContainerView.center, width: hoursSize, height: hoursSize)

        
        // add tickers for seconds, mins, and hours here
        hours = Ticker(numOfTicks: 24, frame: hoursRect)
        minutes = Ticker(numOfTicks: 60, frame: minutesRect)
        seconds = Ticker(numOfTicks: 60, frame: circlesContainerView.frame)
        
        hours.initializeStatus(howMany: hoursLeft)
        minutes.initializeStatus(howMany: minutesLeft)
        seconds.initializeStatus(howMany: secondsLeft)

        
        self.view.addSubview(seconds)
        self.view.addSubview(minutes)
        self.view.addSubview(hours)

        
        var cenX = circlesContainerView.frame.origin.x + (circlesContainerView.frame.width/2)
        var cenY = circlesContainerView.frame.origin.y + (circlesContainerView.frame.height/2)
        print("CircleContainersView is width: \(circlesContainerView.frame.width)")
        print("CircleContainersView is height: \(circlesContainerView.frame.height)")
        print("CircleContainersView is center x: \(cenX)")
        print("CircleContainersView is center y: \(cenY)")

        print("-----------------------------------------")
  
        cenX = hours.frame.origin.x + (hours.frame.width/2)
        cenY = hours.frame.origin.y + (hours.frame.height/2)
        print("hours is width: \(hours.frame.width)")
        print("hours is height: \(hours.frame.height)")
        print("hours is center x: \(cenX)")
        print("hours is center y: \(cenY)")
        
        print("-----------------------------------------")
        
        cenX = minutes.frame.origin.x + (minutes.frame.width/2)
        cenY = minutes.frame.origin.y + (minutes.frame.height/2)
        print("minutes is width: \(minutes.frame.width)")
        print("minutes is height: \(minutes.frame.height)")
        print("minutes is center x: \(cenX)")
        print("minutes is center y: \(cenY)")
        
        print("-----------------------------------------")
        
        cenX = seconds.frame.origin.x + (seconds.frame.width/2)
        cenY = seconds.frame.origin.y + (seconds.frame.height/2)
        print("seconds is width: \(seconds.frame.width)")
        print("seconds is height: \(seconds.frame.height)")
        print("seconds is center x: \(cenX)")
        print("seconds is center y: \(cenY)")
        
        topLabel.text = "container x: \(circlesContainerView.center.x)"
        bottomLabel.text = "seconds x: \(seconds.center.x)"
        
        
        initializeTickers()
    
        
        
        // use a timer to update the times
        Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(ConcentricCirclesViewController.updateDifferenceTime), userInfo: nil, repeats: true)
        
        
        
        let pieFillView = PieFill()
        pieFillView.frame = CGRect(center: circlesContainerView.center, width: hoursSize*0.6, height: hoursSize*0.6)
        
        self.view.addSubview(pieFillView)
        
        
//        
//        let pieChartView = PieChartView()
//        pieChartView.frame = CGRect(x: 0, y: 0, width: view.frame.size.width, height: 400)
//        pieChartView.segments = [
//            Segment(color: .red, value: 57),
//            Segment(color: .blue, value: 30),
//            Segment(color: .green, value: 25),
//            Segment(color: .yellow, value: 40)
//        ]
//        circlesContainerView.addSubview(pieChartView)
        
        
        
        
    }
    
    
    
    
    @objc func updateDifferenceTime() {
        today = Date()
        
        
        
        
        let components = (Calendar.current as NSCalendar).components([.second, .minute, .hour, .day], from: today,
                                                                     to: countdownDate, options: [])
        
        
        daysLeft = components.day
        hoursLeft = components.hour
        minutesLeft = components.minute
        secondsLeft = components.second
        
        
        // Update labels
        
        topLabel.text    = "\(daysLeft!) days left"
        topMiddleLabel.text   = "\(hoursLeft!)"
        bottomMiddleLabel.text = "\(minutesLeft!)"
        bottomLabel.text = "\(secondsLeft!)"
        
        
        // update tickers
        // just use initilize for now
        hours.updateStatus(howMany: hoursLeft)
        minutes.updateStatus(howMany: minutesLeft)
        seconds.updateStatus(howMany: secondsLeft)
        
        
    }
    
    
    
    func initializeTickers() {
        // eventually move the uploading of the tickers here
        
        updateDifferenceTime()
        
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
