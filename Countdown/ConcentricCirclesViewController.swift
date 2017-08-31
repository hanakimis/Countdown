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
    
    @IBOutlet weak var topLabel: UILabel!
    @IBOutlet weak var bottomLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
   

        let minutesSize = circlesContainerView.frame.width * 0.8
        let hoursSize = circlesContainerView.frame.width * 0.6

        let minutesRect = CGRect(center: circlesContainerView.center, width: minutesSize, height: minutesSize)
        let hoursRect = CGRect(center: circlesContainerView.center, width: hoursSize, height: hoursSize)

        
        // add tickers for seconds, mins, and hours here
        let hours = Ticker(numOfTicks: 24, frame: hoursRect)
        let minutes = Ticker(numOfTicks: 60, frame: minutesRect)
        let seconds = Ticker(numOfTicks: 60, frame: circlesContainerView.frame)
        
        circlesContainerView.backgroundColor = UIColor.red
        
        circlesContainerView.addSubview(seconds)
        circlesContainerView.addSubview(minutes)
        circlesContainerView.addSubview(hours)
                
        
        topLabel.text = "container x: \(circlesContainerView.center.x)"
        bottomLabel.text = "seconds x: \(seconds.center.x)"
        
        
        hours.initializeStatus(howMany: 20)
        
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
