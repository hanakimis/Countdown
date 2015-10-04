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
            println("some stuff " + date.description)
  //          dateDisplayLabel.text = date.description
        } else {
            date = datePicker.date
        }
    }
  
    
    func datePickerChanged(datePicker:UIDatePicker) {
        var dateFormatter = NSDateFormatter()
        
        dateFormatter.dateStyle = NSDateFormatterStyle.FullStyle
        

        
        var futureDate = datePicker.date
        var strDate = dateFormatter.stringFromDate(futureDate)
        
        var difference = futureDate.timeIntervalSinceNow
        
        
        
        var calendar: NSCalendar = NSCalendar.currentCalendar()
        
        
        let date = NSDate()
        let formatter = NSDateFormatter()
        formatter.timeStyle = .ShortStyle
//        formatter.stringFromDate(date)
        
        
        
        
        
        let components = NSCalendar.currentCalendar().components(.CalendarUnitSecond |
            .CalendarUnitMinute | .CalendarUnitHour | .CalendarUnitDay |
            .CalendarUnitMonth | .CalendarUnitYear, fromDate: date,
            toDate: datePicker.date, options: nil)
        
//        
//        println("\(components.second) seconds")
//        println("\(components.minute) minutes")
//        println("\(components.hour) hours")
//        println("\(components.day) days")
        
//        timeLeft.text = String(hoursbetwee)
        
        
        defaults.setObject(datePicker.date, forKey: "date")
        
        var val = defaults.objectForKey("date") as! NSDate
        println(val.description)
        println("entered changed date")

    }
    
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
