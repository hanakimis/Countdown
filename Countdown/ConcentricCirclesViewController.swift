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
    @IBOutlet weak var changeDateButton: UIButton!
    
    @IBOutlet weak var bottomOfDateContainerConstraint: NSLayoutConstraint!
    
    let formatter = DateFormatter()
    let defaults = UserDefaults.standard
    var countdownDate: Date!
    var today = Date()
    
    var hours = Ticker()
    var minutes = Ticker()
    var seconds = Ticker()
    var pieFillView = PieFill()
    
    
    var daysLeft: Int! = 0
    var hoursLeft: Int! = 0
    var minutesLeft: Int! = 0
    var secondsLeft: Int! = 0
    
    var datePickerContainerOpen = false
    var thereWasAlreadyDate = false


    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set the style for the datepicker, and the date control
        datePickerChooserStyle()
        
        // if a date is already stored in user defaults, use it
        if let myDate = defaults.object(forKey: "date") {
            thereWasAlreadyDate = true
            print("There is a stored date")

            countdownDate = myDate as! Date

            if countdownDate > Date() {
                print("the stored date is later than today - still time left to the stored date")
                
                // set the datepicker to this target date by default
                datePicker.date = countdownDate
                
                // set the style of the button text
                formatter.locale = Locale(identifier: "en_US")
                let myStringafd = formatter.string(from: countdownDate)
                changeDateButton.setTitle(myStringafd, for: UIControlState.normal)
                
        
                // set the circles
                setupCircles()
                
                // start the countdown
                Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(ConcentricCirclesViewController.updateTickers), userInfo: nil, repeats: true)

                
                
            } else {
                print("the stored date has passed")

                // show the date has already passed, and ask user to input a new date
                // open the datepicker

                displayDatePassed()
                setDateStartup()
            }
            
        } else {
            print("NO stored date exists")
            // this means date hasn't been set in User Defaults
            // open the datepicker, and setup to input a date
            // Temporary setupL: countdownDate = Calendar.current.date(byAdding: .day, value: 1, to: today)!
            

            setDateStartup()
        }
        

    }
    
    
    @IBAction func tapDateButton(_ sender: Any) {
        today = Date()
        let components = (Calendar.current as NSCalendar).components([.second, .minute, .hour, .day], from: today,
                                                                     to: self.datePicker.date, options: [])
        
        daysLeft = components.day
        hoursLeft = components.hour
        minutesLeft = components.minute
        secondsLeft = components.second
     
//        print("number of days left \(daysLeft)")
//        print("number of hours left \(hoursLeft)")
//        print("number of minutes left \(minutesLeft)")
//        print("number of seconds left \(secondsLeft)")
        
        
        // clicking this button should either open or close the date-picker
        // probably should check to make sure the date chosen is logical
        if (self.datePickerContainerOpen) {
            closeDatePicker()
        } else {
            openDatePicker()
        }

        
    }
    
    
    
    
    // setup the date style and other UI elements for the ViewController
    func datePickerChooserStyle() {
        // setup datepicker style
        formatter.dateStyle = .medium
        self.datePicker.setValue(UIColor.white, forKeyPath: "textColor")
        self.datePicker.minimumDate = today
        datePickerContainerOpen = false
    }
    
    
    func displayDatePassed() {
        print("date has passed")
        // show the stuffs
        
    }
    
    
    // this basically pushes the users to add in a date
    func setDateStartup() {
        // need to intialize the timeleft
        // pieFillView.initialDaysLeft(initialDaysLeft: Int())
        // use nsdefaults to store initialDaysLeft
        
        openDatePicker()

    }
    
    
    
    func setupCircles() {
        
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
        pieFillView.frame = pieRect
        
        
        // 4. Add the subviews
        self.view.addSubview(seconds)
        self.view.addSubview(minutes)
        self.view.addSubview(hours)
        self.view.addSubview(pieFillView)
        
        
    }

    
    func updateDifferenceTime() {
        today = Date()
        let components = (Calendar.current as NSCalendar).components([.second, .minute, .hour, .day], from: today,
                                                                     to: countdownDate, options: [])
        

        daysLeft = components.day
        hoursLeft = components.hour
        minutesLeft = components.minute
        secondsLeft = components.second
        
        
//        print("today's Date: \(today)")
//        print("countdown Date: \(countdownDate)")
//
//        print("days left \(daysLeft)")
//        print("hours left \(hoursLeft)")
//        print("minutes left \(minutesLeft)")
//        print("seconds left \(secondsLeft)")

    }
    

    @objc func updateTickers() {
        // eventually move the uploading of the tickers here
        updateDifferenceTime()
        
        hours.updateStatus(howMany: hoursLeft)
        minutes.updateStatus(howMany: minutesLeft)
        seconds.updateStatus(howMany: secondsLeft)
        pieFillView.updateFill(daysLeft: CGFloat(daysLeft), totalsDays: CGFloat(daysLeft))
    }
    
    
    
    func openDatePicker() {
        
        // check to see if the date is already been there
        // need to also check to see if the stored date has passed
        //self.datePicker.date =  Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        
        
        
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
        countdownDate = self.datePicker.date
        defaults.set(countdownDate, forKey: "date")
        
        let components = (Calendar.current as NSCalendar).components([.second, .minute, .hour, .day], from: Date(),
                                                                     to: countdownDate, options: [])
        
        defaults.set(components.day, forKey: "totalTime")
        
        // do we need to do stuff if there was already a date set?
        updateTickers()
        formatter.locale = Locale(identifier: "en_US")
        let myStringafd = formatter.string(from: countdownDate)
        changeDateButton.setTitle(myStringafd, for: UIControlState.normal)
        
        
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
            Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(ConcentricCirclesViewController.updateTickers), userInfo: nil, repeats: true)
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
