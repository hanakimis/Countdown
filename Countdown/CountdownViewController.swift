//
//  CountdownViewController.swift
//  Countdown
//
//  Created by Hana Kim on 3/9/15.
//  Copyright (c) 2015 Hana Kim. All rights reserved.
//

import UIKit

class CountdownViewController: UIViewController {

    @IBOutlet weak var datePicker: UIDatePicker!
    
    @IBOutlet weak var todaysDateLabel: UILabel!
    @IBOutlet weak var monthsLeftLabel: UILabel!
    @IBOutlet weak var daysLeftlabel: UILabel!
    @IBOutlet weak var hoursLeftLabel: UILabel!
    @IBOutlet weak var minutesLeftLabel: UILabel!
    @IBOutlet weak var secondsLeftLabel: UILabel!
    @IBOutlet weak var toggleDateChanger: UIButton!
    
    @IBOutlet weak var toggleDateChangerSmallWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var toggleDateChangerFullWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var updateDateBottomLayoutConstraint: NSLayoutConstraint!
    
    
    let formatter = NSDateFormatter()
    let defaults = NSUserDefaults.standardUserDefaults()
    var countdownDate: NSDate!
    var today = NSDate()
    var datePickerContainerOpen = false
    
    var temp = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setup the date style
        formatter.dateStyle = .ShortStyle

        
        // setup the datepicker
        datePicker.datePickerMode = UIDatePickerMode.Date
        datePicker.minimumDate = today
        
        
        // update if a date has been stored
        // need to do a check to see if the date is before today
        if let myDate = defaults.objectForKey("date") {
            countdownDate = myDate as! NSDate
            datePicker.date = countdownDate
        } else {
            countdownDate = datePicker.date
        }
        
        // update the labels
        updateDifferenceLabels()

        // use a timer to update the times
        NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: Selector("updateDifferenceLabels"), userInfo: nil, repeats: true)

        closeDatePicker()
    }
  
    
    @IBAction func toggleDateChangerClicked(sender: AnyObject) {
        if datePickerContainerOpen {
            closeDatePicker()
        } else {
            openDatePicker()
        }
    }
    
    
    @IBAction func chooseNewDate(sender: AnyObject) {
        countdownDate = datePicker.date
        defaults.setObject(countdownDate, forKey: "date")
        updateDifferenceLabels()
        closeDatePicker()
    }
    
    
    func openDatePicker() {

        UIView.animateWithDuration(0.3, animations: { () -> Void in
            self.toggleDateChanger.setTitle("X", forState: .Normal)
            self.toggleDateChangerSmallWidthConstraint.priority = 750
            self.toggleDateChangerFullWidthConstraint.priority = 250
            self.updateDateBottomLayoutConstraint.constant = 0
            
            self.view.layoutIfNeeded()

            // animate the countdown date label
            
            self.datePicker.alpha = 1

            }) { (Bool) -> Void in
                self.datePickerContainerOpen = true
        }
    }
    
    
    func closeDatePicker() {
        
        UIView.animateWithDuration(0.3, animations: { () -> Void in
            self.datePicker.alpha = 0
            
            self.toggleDateChanger.setTitle(self.formatter.stringFromDate(self.datePicker.date), forState: .Normal)
            self.toggleDateChangerSmallWidthConstraint.priority = 250
            self.toggleDateChangerFullWidthConstraint.priority = 750
            self.updateDateBottomLayoutConstraint.constant = -160
        
            self.view.layoutIfNeeded()
            
            }) { (Bool) -> Void in
                self.datePickerContainerOpen = false
        }
    }
    
    
    func updateDifferenceLabels() {
        today = NSDate()
        
        let components = NSCalendar.currentCalendar().components([.Second, .Minute, .Hour, .Day, .Month], fromDate: today,
            toDate: countdownDate, options: [])

        monthsLeftLabel.text  = "\(components.month) months"
        daysLeftlabel.text    = "\(components.day) days"
        hoursLeftLabel.text   = "\(components.hour) hours"
        minutesLeftLabel.text = "\(components.minute) minutes"
        secondsLeftLabel.text = "\(components.second) seconds"
        
        todaysDateLabel.text = formatter.stringFromDate(today)
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
