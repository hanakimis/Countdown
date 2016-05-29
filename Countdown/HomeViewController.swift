//
//  HomeViewController.swift
//  Countdown
//
//  Created by Hana Kim on 5/29/16.
//  Copyright © 2016 Hana Kim. All rights reserved.
//

import UIKit

class HomeViewController: UIViewController {

    
    @IBOutlet weak var totalProgressView: TotalRemainingUIView!
    
    @IBOutlet weak var numberLeftLabel: UILabel!
    @IBOutlet weak var unitsLeftLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        updateLabel()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func updateLabel() {
        numberLeftLabel.text = "45"
        unitsLeftLabel.text = "days left"
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
