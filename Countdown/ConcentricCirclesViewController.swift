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
        
        
        // 0. Set size and location of the reference frame
        circlesContainerView.frame.size.width = self.view.frame.width * 0.8
        circlesContainerView.frame.size.height = circlesContainerView.frame.width

        
        // 1. Get the date
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
        
        
        // 2. Figure out the difference between the target date and right now
        let components = (Calendar.current as NSCalendar).components([.second, .minute, .hour, .day], from: today,
                                                                     to: countdownDate, options: [])
        
        daysLeft = components.day
        hoursLeft = components.hour
        minutesLeft = components.minute
        secondsLeft = components.second
        
        
        
        // 3. Update the tickers
        let minutesSize = circlesContainerView.frame.width * 0.8
        let hoursSize = circlesContainerView.frame.width * 0.6

        let minutesRect = CGRect(center: circlesContainerView.center, width: minutesSize, height: minutesSize)
        let hoursRect = CGRect(center: circlesContainerView.center, width: hoursSize, height: hoursSize)

        
        // add tickers for seconds, mins, and hours here
        var tickL:CGFloat = 24.0
        hours = Ticker(numOfTicks: 24, tickLength: tickL, frame: hoursRect)
        
        tickL = 20.0
        minutes = Ticker(numOfTicks: 60, tickLength: tickL, frame: minutesRect)
        
        tickL = 16.0
        seconds = Ticker(numOfTicks: 60, tickLength: tickL, frame: circlesContainerView.frame)
        
        hours.initializeStatus(howMany: hoursLeft)
        minutes.initializeStatus(howMany: minutesLeft)
        seconds.initializeStatus(howMany: secondsLeft)

        
        // 4. Add the tickers
        self.view.addSubview(seconds)
        self.view.addSubview(minutes)
        self.view.addSubview(hours)
        
 
        initializeTickers()
    
        
        // 5. use a timer to update the times
        Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(ConcentricCirclesViewController.updateDifferenceTime), userInfo: nil, repeats: true)
        
        
        // 6. add the pie in the middle
        let pieFillView = PieFill()
        pieFillView.frame = CGRect(center: circlesContainerView.center, width: hoursSize*0.6, height: hoursSize*0.6)
        
        self.view.addSubview(pieFillView)
        
    }
    
    
    
    
    @objc func updateDifferenceTime() {
        today = Date()

        let components = (Calendar.current as NSCalendar).components([.second, .minute, .hour, .day], from: today,
                                                                     to: countdownDate, options: [])
        
        daysLeft = components.day
        hoursLeft = components.hour
        minutesLeft = components.minute
        secondsLeft = components.second
        
        
        
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
