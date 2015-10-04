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
    
    @IBOutlet weak var timeLeft: UILabel!
    
    var defaults = NSUserDefaults.standardUserDefaults()
    
    var date: NSDate!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        datePicker.addTarget(self, action: Selector("datePickerChanged:"), forControlEvents: UIControlEvents.ValueChanged)
        datePicker.datePickerMode = UIDatePickerMode.Date
        
        if (defaults.objectForKey("date") != nil) {
            date = defaults.objectForKey("date") as! NSDate
            dateDisplayLabel.text = date.description
        } else {
            date = datePicker.date
        }
    }
  
    
    func datePickerChanged(datePicker:UIDatePicker) {
        let dateFormatter = NSDateFormatter()
        
        dateFormatter.dateStyle = NSDateFormatterStyle.FullStyle
        

        
//        let futureDate = datePicker.date
//        var strDate = dateFormatter.stringFromDate(futureDate)
//        var difference = futureDate.timeIntervalSinceNow
//        var calendar: NSCalendar = NSCalendar.currentCalendar()
        
        
        let date = NSDate()
        let formatter = NSDateFormatter()
        formatter.timeStyle = .ShortStyle
        formatter.stringFromDate(date)
        
        
        
        
        
        let components = NSCalendar.currentCalendar().components([.Second, .Minute, .Hour, .Day, .Month, .Year], fromDate: date,
            toDate: datePicker.date, options: [])
        
        print("******************************************************")
        print("\(components.second) seconds")
        print("\(components.minute) minutes")
        print("\(components.hour) hours")
        print("\(components.day) days")
        
//        timeLeft.text = String(hoursbetween)
        
        
        defaults.setObject(datePicker.date, forKey: "date")
        
        let val = defaults.objectForKey("date") as! NSDate

    }
    
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
