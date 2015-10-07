//
//  CountdownViewController.swift
//  Countdown
//
//  Created by Hana Kim on 3/9/15.
//  Copyright (c) 2015 Hana Kim. All rights reserved.
//

import UIKit

class CountdownViewController: UIViewController {

    
    @IBOutlet weak var dateDisplayLabel: UILabel!
    @IBOutlet weak var datePicker: UIDatePicker!
    
    @IBOutlet weak var daysLeftlabel: UILabel!
    @IBOutlet weak var hoursLeftLabel: UILabel!
    @IBOutlet weak var minutesLeftLabel: UILabel!
    @IBOutlet weak var secondsLeftLabel: UILabel!
    
    
    
    let defaults = NSUserDefaults.standardUserDefaults()
    var date: NSDate!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        datePicker.addTarget(self, action: Selector("datePickerChanged:"), forControlEvents: UIControlEvents.ValueChanged)
        datePicker.datePickerMode = UIDatePickerMode.Date
        
        if let myDate = defaults.objectForKey("date") {
            date = myDate as! NSDate
            dateDisplayLabel.text = myDate.description
        } else {
            date = datePicker.date
        }
    }
  
    
    func datePickerChanged(datePicker:UIDatePicker) {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = NSDateFormatterStyle.FullStyle
        
        // create a new date object for today
        let today = NSDate()
        let formatter = NSDateFormatter()
        formatter.timeStyle = .ShortStyle
        formatter.stringFromDate(today)
        
        
        let components = NSCalendar.currentCalendar().components([.Second, .Minute, .Hour, .Day, .Month, .Year], fromDate: today,
            toDate: datePicker.date, options: [])
        
        daysLeftlabel.text    = "\(components.day) days"
        hoursLeftLabel.text   = "\(components.hour) hours"
        minutesLeftLabel.text = "\(components.minute) minutes"
        secondsLeftLabel.text = "\(components.second) seconds"
        
        
        defaults.setObject(datePicker.date, forKey: "date")
        dateDisplayLabel.text = today.description
        print("updated defaults date")
    }
    
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
