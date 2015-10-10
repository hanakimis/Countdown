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
    @IBOutlet weak var countdownDateLabel: UILabel!
    
    @IBOutlet weak var monthsLeftLabel: UILabel!
    @IBOutlet weak var daysLeftlabel: UILabel!
    @IBOutlet weak var hoursLeftLabel: UILabel!
    @IBOutlet weak var minutesLeftLabel: UILabel!
    @IBOutlet weak var secondsLeftLabel: UILabel!
    
    @IBOutlet weak var toggleDateChanger: UIButton!
    @IBOutlet weak var updateDateBottomLayoutConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var countdownDateLabelTopConstraint: NSLayoutConstraint!
    
    
    
    
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
        datePicker.addTarget(self, action: Selector("datePickerChanged:"), forControlEvents: UIControlEvents.ValueChanged)

        
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
        NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: Selector("updateTime"), userInfo: nil, repeats: true)

        closeDatePicker()
    }
  
    
    func datePickerChanged(datePicker:UIDatePicker) {
        countdownDate = datePicker.date
        
        
        defaults.setObject(countdownDate, forKey: "date")

        updateDifferenceLabels()
    }
    
    
    @IBAction func toggleDateChangerClicked(sender: AnyObject) {
        if datePickerContainerOpen {
            closeDatePicker()
        } else {
            openDatePicker()
        }
    }
    
    
    
    
    func openDatePicker() {
        datePicker.alpha = 1


        UIView.animateWithDuration(0.3, animations: { () -> Void in
            // toggle the date picker size to small/ close datePicker
            
            self.updateDateBottomLayoutConstraint.constant = 0
            
            self.view.layoutIfNeeded()

            // animate the countdown date label
            
            }) { (Bool) -> Void in
                 // when finished, show the date picker
                self.datePicker.alpha = 1
                self.datePickerContainerOpen = true
        }
    }
    
    
    func closeDatePicker() {
        datePicker.alpha = 0
        
        updateDateBottomLayoutConstraint.constant = -160
        countdownDateLabelTopConstraint.constant = 20
        
        self.view.layoutIfNeeded()
        
        datePickerContainerOpen = false
    }
    
    
    
    func updateTime() {
        updateDifferenceLabels()
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
        countdownDateLabel.text = formatter.stringFromDate(countdownDate)
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
