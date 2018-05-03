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
    var daysLeftLabel: UILabel!
    
    
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
        
        
        // if a date is already stored in user defaults, use it
        
        
        if (defaults.object(forKey: "YourKey") != nil) {
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
                
        
                // set the circles
                setupCircles()
                
                // start the countdown
                Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(ConcentricCirclesViewController.updateTickers), userInfo: nil, repeats: true)

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
        

    }

    
    @IBAction func tapDateButton(_ sender: Any) {
        if (self.datePickerContainerOpen) {
            closeDatePicker()
        } else {
            openDatePicker()
        }
    }
    
    
    func displayDatePassed() {
        // have a message box in the middle
        // set label: you made it
        // confetti
        
        // clear NS Defaults
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
        
        
        // 1. Setup the actual UI Views for each of the visualizations
        hours = Ticker(numOfTicks: 24, tickLength: tickLHours, frame: hoursRect)
        minutes = Ticker(numOfTicks: 60, tickLength: tickLMinutes, frame: minutesRect)
        seconds = Ticker(numOfTicks: 60, tickLength: tickLSeconds, frame: secondsRect)
        pieFillView.frame = pieRect
        
        
        // 2. Update the center labels
        var labelCenter = CGPoint(x: hours.center.x, y: hours.center.y + 10.0)
        let label = UILabel(frame: CGRect(center: labelCenter, radius: 30.0))
        
        label.font = UIFont.systemFont(ofSize: 12.0)
        label.text = "days left"
        label.textAlignment = .center
        label.textColor = UIColor.white
        
        labelCenter = CGPoint(x: hours.center.x, y: hours.center.y - 10.0)
        
        daysLeftLabel = UILabel(frame: CGRect(center: labelCenter, radius: 30.0))
        daysLeftLabel.font = UIFont.systemFont(ofSize: 24.0)
        daysLeftLabel.text = String(daysLeft)
        daysLeftLabel.textAlignment = .center
        daysLeftLabel.textColor = UIColor.white
        
        
        // 3. Add the views to this view
        //    Probably should refactor to add to circlesContainerView instead of this VC's view
        self.view.addSubview(seconds)
        self.view.addSubview(minutes)
        self.view.addSubview(hours)
        self.view.addSubview(pieFillView)
        self.view.addSubview(label)
        self.view.addSubview(daysLeftLabel)
        
    }


    @objc func updateTickers() {
        today = Date()
        let components = (Calendar.current as NSCalendar).components([.second, .minute, .hour, .day], from: today, to: countdownDate, options: [])
        
        daysLeft = components.day
        hoursLeft = components.hour
        minutesLeft = components.minute
        secondsLeft = components.second
        
        hours.updateStatus(howMany: hoursLeft)
        minutes.updateStatus(howMany: minutesLeft)
        seconds.updateStatus(howMany: secondsLeft)
        pieFillView.updateFill(daysLeft: CGFloat(daysLeft), totalsDays: CGFloat(daysLeft))
        daysLeftLabel.text = String(daysLeft)
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
        
        // update the target date
        // update the time left
        countdownDate = self.datePicker.date
        let components = (Calendar.current as NSCalendar).components([.second, .minute, .hour, .day], from: Date(), to: countdownDate, options: [])
        defaults.set(components.day, forKey: "date")
        defaults.set(components.day, forKey: "totalTime")
        
        // do we need to do stuff if there was already a date set?
        updateTickers()
        formatter.locale = Locale(identifier: "en_US")
        let myStringafd = formatter.string(from: countdownDate)
        changeDateButton.setTitle(myStringafd, for: UIControlState.normal)
        
        UIView.animate(withDuration: 0.3, animations: { () -> Void in
            self.bottomOfDateContainerConstraint.constant = 30-(self.dateChangeContainerView.frame.height)
            self.changeDateButton.backgroundColor = UIColor.clear
            self.datePicker.alpha = 0.0
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
