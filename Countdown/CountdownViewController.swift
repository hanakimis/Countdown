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
    
    
    let formatter = NSDateFormatter()
    let defaults = NSUserDefaults.standardUserDefaults()
    var countdownDate: NSDate!
    let today = NSDate()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // setup the date style
        formatter.dateStyle = .ShortStyle

        
        // setup the datepicker
        datePicker.datePickerMode = UIDatePickerMode.Date
        datePicker.minimumDate = today
        datePicker.addTarget(self, action: Selector("datePickerChanged:"), forControlEvents: UIControlEvents.ValueChanged)

        
        // update if a date has been stored
        if let myDate = defaults.objectForKey("date") {
            countdownDate = myDate as! NSDate
            datePicker.date = countdownDate
        } else {
            countdownDate = datePicker.date
        }
        
        //update the labels
        updateDifferenceLabels()

    }
  
    
    func datePickerChanged(datePicker:UIDatePicker) {
        countdownDate = datePicker.date
        defaults.setObject(countdownDate, forKey: "date")

        updateDifferenceLabels()
    }
    
    
    func updateDifferenceLabels() {
        let components = NSCalendar.currentCalendar().components([.Second, .Minute, .Hour, .Day, .Month], fromDate: today,
            toDate: datePicker.date, options: [])

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
