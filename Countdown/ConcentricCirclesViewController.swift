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
    @IBOutlet weak var dateChangeContainerView: UIView!
    @IBOutlet weak var datePicker: UIDatePicker!
    
    @IBOutlet weak var bottomOfDateContainerConstraint: NSLayoutConstraint!
    
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
    
    var datePickerContainerOpen = false


    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        
        updateDifferenceTime()
        Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(ConcentricCirclesViewController.updateTickers), userInfo: nil, repeats: true)
    }
    
    // setup the date style and other UI elements for the ViewController
    func setupUI() {
        // setup datepicker
        formatter.dateStyle = .medium
        self.datePicker.setValue(UIColor.white, forKeyPath: "textColor")
        self.datePicker.minimumDate = today
        datePickerContainerOpen = false

        checkTargetDateSet()
    }
    
    
    func checkTargetDateSet() {
        // 1. Get the date
        // update if a date has been stored
        // need to do a check to see if the date is before today
        if let myDate = defaults.object(forKey: "date") {
            
            //if a date has been set already, use this as the target date, unless date has past already
            if countdownDate < Date() {
                countdownDate = myDate as! Date
                // set the datepicker to this target date
                datePicker.date = countdownDate

                // set the circles
                setupCircles(countdownDate: countdownDate)
                
            } else {
                // show the date has already passed, and ask user to input a new date
                displayDatePassed()
                setDateStartup()
            }
            
        } else {
            // this means date hasn't been set
            // open the datepicker, and setup to input a date
            // countdownDate = Calendar.current.date(byAdding: .day, value: 1, to: today)!
            setDateStartup()
        }
    }
    
    func displayDatePassed() {
        print("date has passed")
        // show the stuffs
    }
    
    func setDateStartup() {
        
        
        // need to intialize the timeleft
    }
    
    
    
    func setupCircles(countdownDate: Date) {
        
        // 0. Set size and location of frames
        circlesContainerView.frame.size.width = self.view.frame.width * 0.8
        circlesContainerView.frame.size.height = circlesContainerView.frame.width
        
        let minutesSize = circlesContainerView.frame.width * 0.8
        let hoursSize = circlesContainerView.frame.width * 0.6
        let pieSize = circlesContainerView.frame.width * 0.6 * 0.6
        
        let secondsRect = circlesContainerView.frame
        let minutesRect = CGRect(center: circlesContainerView.center, width: minutesSize, height: minutesSize)
        let hoursRect = CGRect(center: circlesContainerView.center, width: hoursSize, height: hoursSize)
        let pieRect = CGRect(center: circlesContainerView.center, width: pieSize, height: pieSize)
        
        let tickLHours:CGFloat = 24.0
        let tickLMinutes:CGFloat = 20.0
        let tickLSeconds:CGFloat = 16.0
        

        

        
         // 3. Update the tickers
        // add tickers for seconds, mins, and hours here
        hours = Ticker(numOfTicks: 24, tickLength: tickLHours, frame: hoursRect)
        minutes = Ticker(numOfTicks: 60, tickLength: tickLMinutes, frame: minutesRect)
        seconds = Ticker(numOfTicks: 60, tickLength: tickLSeconds, frame: secondsRect)
        
        var pieFillView = PieFill()
        pieFillView.frame = pieRect
        
        
        // 4. Add the tickers
        self.view.addSubview(seconds)
        self.view.addSubview(minutes)
        self.view.addSubview(hours)
        self.view.addSubview(pieFillView)
        
        
        // 5. set the dates
        // Figure out the difference between the target date and right now
        updateDifferenceTime()
        
        hours.initializeStatus(howMany: hoursLeft)
        minutes.initializeStatus(howMany: minutesLeft)
        seconds.initializeStatus(howMany: secondsLeft)
        //
        pieFillView.setDaysLeft(daysLeft: Int(daysLeft))

    }

    
    
   
    
    
    func updateDifferenceTime() {
        today = Date()
        let components = (Calendar.current as NSCalendar).components([.second, .minute, .hour, .day], from: today,
                                                                     to: countdownDate, options: [])
        
        daysLeft = components.day
        hoursLeft = components.hour
        minutesLeft = components.minute
        secondsLeft = components.second
    }
    

    @objc func updateTickers() {
        // eventually move the uploading of the tickers here
        updateDifferenceTime()
        
        hours.updateStatus(howMany: hoursLeft)
        minutes.updateStatus(howMany: minutesLeft)
        seconds.updateStatus(howMany: secondsLeft)
    }
    
    func openDatePicker() {
        UIView.animate(withDuration: 0.3, animations: { () -> Void in
            
            //            self.toggleDateChanger.contentEdgeInsets = UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0)
            //            self.toggleDateChangerSmallWidthConstraint.priority = UILayoutPriority(rawValue: 750)
            //            self.toggleDateChangerFullWidthConstraint.priority = UILayoutPriority(rawValue: 250)
            
            //            self.countdownContainerVerticalCenterConstraint.priority = UILayoutPriority(rawValue: 250)
            //            self.countdownContainerVerticalTopConstraint.priority = UILayoutPriority(rawValue: 750)
            
            self.dateChangeContainerView.alpha = 1
            self.bottomOfDateContainerConstraint.constant = 0
            
            self.view.layoutIfNeeded()
            
            
        }, completion: { (Bool) -> Void in
            self.datePickerContainerOpen = true
        })
    }
    
    func closeDatePicker() {
        
        // update the target date
        // update the time left
        
        UIView.animate(withDuration: 0.3, animations: { () -> Void in
            
            //            self.toggleDateChangerSmallWidthConstraint.priority = UILayoutPriority(rawValue: 250)
            //            self.toggleDateChangerFullWidthConstraint.priority = UILayoutPriority(rawValue: 750)
            
            //            self.countdownContainerVerticalCenterConstraint.priority = UILayoutPriority(rawValue: 750)
            //            self.countdownContainerVerticalTopConstraint.priority = UILayoutPriority(rawValue: 250)
            
            
            self.dateChangeContainerView.alpha = 0
            self.bottomOfDateContainerConstraint.constant = -(self.dateChangeContainerView.frame.height)
            
            
            self.view.layoutIfNeeded()
            
        }, completion: { (Bool) -> Void in
            self.datePickerContainerOpen = false
        })
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
