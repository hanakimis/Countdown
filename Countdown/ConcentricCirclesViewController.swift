//
//  ConcentricCirclesViewController.swift
//  Countdown
//
//  Created by Hana Kim on 8/24/17.
//  Copyright © 2017 Hana Kim. All rights reserved.
//

import UIKit

class ConcentricCirclesViewController: UIViewController {

    
    @IBOutlet weak var contentContainerView: UIView!
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
    var timeLeftLabel: UILabel!
    var timeLeftScaleLabel: UILabel!
    
    var completedView: UIView!
    var timer : Timer?
    
    var daysLeft: Int! = 0
    var hoursLeft: Int! = 0
    var minutesLeft: Int! = 0
    var secondsLeft: Int! = 0
    
    var datePickerContainerOpen = false
    var thereWasAlreadyDate = false


    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setup datepicker style
        formatter.dateStyle = .medium
        self.datePicker.setValue(UIColor.white, forKeyPath: "textColor")
        self.datePicker.minimumDate = today
        datePickerContainerOpen = false
        
        setupCircles()
        
        // if a date is already stored in user defaults, use it
        if (defaults.object(forKey: "date") != nil) {
            let myDate = defaults.object(forKey: "date")
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
                
                
                // start the countdown
                startTimer()
                closeDatePicker()
                
            } else {
                print("the stored date has passed")

                // show the date has already passed, and ask user to input a new date
                // open the datepicker

                displayDatePassed()
                openDatePicker()
            }
            
        } else {
            print("NO stored date exists")
            // this means date hasn't been set in User Defaults
            // do something for setup of the circles
        
            openDatePicker()
        }
        
        
//       displayDatePassed()

    }

    
    @IBAction func tapDateButton(_ sender: Any) {
        if (self.datePickerContainerOpen) {
            closeDatePicker()
        } else {
            openDatePicker()
        }
    }
    
    
    func startTimer() {
        if timer == nil {
            timer =  Timer.scheduledTimer(
                timeInterval: TimeInterval(0.3),
                target      : self,
                selector    : #selector(ConcentricCirclesViewController.updateTickers),
                userInfo    : nil,
                repeats     : true)
        }
    }
    
    
    func displayDatePassed() {
        // have a message box in the middle
        // set label: you made it
        // confetti
        
        completedView = UIView()
        completedView.frame.origin = circlesContainerView.frame.origin
        completedView.frame.size.width = self.view.frame.width
        completedView.frame.size.height = self.view.frame.width

//        completedView.backgroundColor = UIColor.purple
        //completedView.backgroundColor = UIColor(rgb: 0x262B31)
    

        var labelCenter = CGPoint(x: completedView.center.x, y: completedView.center.y + 20.0)
        
        let congrats = UILabel(frame: CGRect(center: labelCenter, width: 200.0, height: 50.0))
        congrats.font = UIFont.systemFont(ofSize: 30.0)
        congrats.text = "Congrats!"
        congrats.textColor = UIColor.white
        congrats.font = congrats.font.withSize(30.0)
        
        let message = UILabel(frame: CGRect(center: labelCenter, width: 200.0, height: 50.0))
        message.font = UIFont.systemFont(ofSize: 30.0)
        message.text = "Congrats!"
        message.textColor = UIColor.white
        message.font = congrats.font.withSize(30.0)
        
        completedView.addSubview(congrats)
        completedView.addSubview(message)
        self.view.addSubview(completedView)

        
        // clear NS Defaults
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        UserDefaults.standard.synchronize()
    }
    
    
    
    func setupCircles() {
        // 0. Set size and location of frames
//        circlesContainerView.backgroundColor = UIColor.brown
        
        let circlesCenter = circlesContainerView.frame.width / 2.0
        let secondsSize = (circlesContainerView.frame.width) / 2.0
        let minutesSize = (circlesContainerView.frame.width * 0.8) / 2.0
        let hoursSize = (circlesContainerView.frame.width * 0.6) / 2.0
        let pieSize = (circlesContainerView.frame.width * 0.6 * 0.6) / 2.0
        
        
        // this is taking the items before it has been resized for the keyboard to be closed
        let secondsRect = CGRect(center: CGPoint(x: circlesCenter, y: circlesCenter), radius: secondsSize)
        let minutesRect = CGRect(center: CGPoint(x: circlesCenter, y: circlesCenter), radius: minutesSize)
        let hoursRect = CGRect(center: CGPoint(x: circlesCenter, y: circlesCenter), radius: hoursSize)
        let pieRect = CGRect(center: CGPoint(x: circlesCenter, y: circlesCenter), radius: pieSize)
        
        
        let tickLHours:CGFloat = 24.0
        let tickLMinutes:CGFloat = 20.0
        let tickLSeconds:CGFloat = 16.0
        
        
        // 1. Setup the actual UI Views for each of the visualizations
        pieFillView.frame = pieRect
        hours = Ticker(numOfTicks: 23, tickLength: tickLHours, frame: hoursRect)
        minutes = Ticker(numOfTicks: 59, tickLength: tickLMinutes, frame: minutesRect)
        seconds = Ticker(numOfTicks: 59, tickLength: tickLSeconds, frame: secondsRect)
        
        
        // 2. Update the center labels
        var labelCenter = CGPoint(x: hours.center.x, y: hours.center.y + 10.0)
        timeLeftScaleLabel = UILabel(frame: CGRect(center: labelCenter, radius: 30.0))
        
        timeLeftScaleLabel.font = UIFont.systemFont(ofSize: 12.0)
        timeLeftScaleLabel.text = "days left"
        timeLeftScaleLabel.textAlignment = .center
        timeLeftScaleLabel.textColor = UIColor.white
        
        labelCenter = CGPoint(x: hours.center.x, y: hours.center.y - 10.0)
        
        timeLeftLabel = UILabel(frame: CGRect(center: labelCenter, radius: 30.0))
        timeLeftLabel.font = UIFont.systemFont(ofSize: 24.0)
        timeLeftLabel.text = String(daysLeft)
        timeLeftLabel.textAlignment = .center
        timeLeftLabel.textColor = UIColor.white
        
        
        // 3. Add the views to this view
        circlesContainerView.addSubview(seconds)
        circlesContainerView.addSubview(minutes)
        circlesContainerView.addSubview(hours)
        circlesContainerView.addSubview(pieFillView)
        circlesContainerView.addSubview(timeLeftScaleLabel)
        circlesContainerView.addSubview(timeLeftLabel)
        
    }

    func initializeTickers(daysLeft: Int, hoursLeft: Int, minutesLeft: Int, secondsLeft: Int) {
        // rotate views
        
        pieFillView.updateFill(daysLeft: CGFloat(daysLeft), totalDaysSet: CGFloat(daysLeft)) // this should really be an initialize function
        hours.initializeStatus(howMany: hoursLeft)
        minutes.initializeStatus(howMany: minutesLeft)
        seconds.initializeStatus(howMany: secondsLeft)
        
        
        UIView.animate(withDuration: 0.3) {
            // rotate hours based on days pie
            var rotation = self.pieFillView.rotationEnd()
            self.hours.transform = CGAffineTransform(rotationAngle: rotation)
            
            // rotate minutes based on hours
            rotation += self.hours.rotationEnd()
            self.minutes.transform = CGAffineTransform(rotationAngle: rotation)
            
            // rotate seconds based on minutes
            rotation += self.minutes.rotationEnd()
            self.seconds.transform = CGAffineTransform(rotationAngle: rotation)
        }
    }
    

    @objc func updateTickers() {
        today = Date()
        let components = (Calendar.current as NSCalendar).components([.second, .minute, .hour, .day], from: today, to: countdownDate, options: [])
        
        daysLeft = components.day
        hoursLeft = components.hour
        minutesLeft = components.minute
        secondsLeft = components.second
        
        updateTimeLeftLabel(days: daysLeft, hours: hoursLeft, mins: minutesLeft, secs: secondsLeft)
        
        
        // TODO: when we set at zero, do a shift for the inside ones
        
        hours.updateStatus(howMany: hoursLeft)
        minutes.updateStatus(howMany: minutesLeft)
        seconds.updateStatus(howMany: secondsLeft)
        pieFillView.updateFill(daysLeft: CGFloat(daysLeft), totalDaysSet: CGFloat(daysLeft))
        
        UIView.animate(withDuration: 0.3) {
            // rotate hours based on days pie
            var rotation = self.pieFillView.rotationEnd()
            self.hours.transform = CGAffineTransform(rotationAngle: rotation)
            
            // rotate minutes based on hours
            rotation += self.hours.rotationEnd()
            self.minutes.transform = CGAffineTransform(rotationAngle: rotation)
            
            // rotate seconds based on minutes
            rotation += self.minutes.rotationEnd()
            self.seconds.transform = CGAffineTransform(rotationAngle: rotation)
        }
    }
    
    
    func updateTimeLeftLabel(days: Int, hours: Int, mins: Int, secs: Int) {
        if (days > 0) {
            timeLeftScaleLabel.text = "days left"
            timeLeftLabel.text = String(days)
        } else if (hours > 0) {
            timeLeftScaleLabel.text = "hours left"
            timeLeftLabel.text = String(hours)
        } else if (mins > 0) {
            timeLeftScaleLabel.text = "mins left"
            timeLeftLabel.text = String(mins)
        } else if (secs > 0) {
            timeLeftScaleLabel.text = "secs left"
            timeLeftLabel.text = String(secs)
        } else {
            // stop timer
            if timer != nil {
                timer?.invalidate()
                timer = nil
            }
            displayDatePassed()
            print("Time has ended")
        }
        
    }
    
    
    func openDatePicker() {
        
        UIView.animate(withDuration: 0.3, animations: { () -> Void in
            // show the date picker by moving it up
            self.bottomOfDateContainerConstraint.constant = 0
            self.changeDateButton.backgroundColor = UIColor(rgb: 0x22252A)
            self.datePicker.alpha = 1.0
            
            self.view.layoutIfNeeded()
            
            // once we update the view that we add the circles into, we can move these more easily
            
        }, completion: { (Bool) -> Void in
            self.datePickerContainerOpen = true
        })
    }
    
    func closeDatePicker() {
        countdownDate = self.datePicker.date
        let components = (Calendar.current as NSCalendar).components([.second, .minute, .hour, .day], from: Date(), to: countdownDate, options: [])
        daysLeft = components.day
        hoursLeft = components.hour
        minutesLeft = components.minute
        secondsLeft = components.second
        
        
        // update the target date
        // update the time left
        defaults.set(countdownDate, forKey: "date")
        defaults.set(components.day, forKey: "totalTime")
        
        // do we need to do stuff if there was already a date set?
        formatter.locale = Locale(identifier: "en_US")
        let myStringafd = formatter.string(from: countdownDate)
        changeDateButton.setTitle(myStringafd, for: UIControlState.normal)
        
        UIView.animate(withDuration: 0.3, animations: { () -> Void in
            self.bottomOfDateContainerConstraint.constant = 30-(self.dateChangeContainerView.frame.height)
            self.changeDateButton.backgroundColor = UIColor.clear
            self.datePicker.alpha = 0.0
            
            self.view.layoutIfNeeded()
            
        }, completion: { (Bool) -> Void in
            self.initializeTickers(daysLeft: self.daysLeft, hoursLeft: self.hoursLeft, minutesLeft: self.minutesLeft, secondsLeft: self.secondsLeft)
            self.startTimer()
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
