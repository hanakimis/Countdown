//
//  CountdownViewController.swift
//  Countdown
//
//  Created by Hana Kim on 3/9/15.
//  Copyright (c) 2015 Hana Kim. All rights reserved.
//

import UIKit
import UserNotifications

class CountdownViewController: UIViewController {

    @IBOutlet weak var datePicker: UIDatePicker!

    @IBOutlet weak var daysLeftlabel: UILabel!
    @IBOutlet weak var hoursLeftLabel: UILabel!
    @IBOutlet weak var minutesLeftLabel: UILabel!
    @IBOutlet weak var secondsLeftLabel: UILabel!
    @IBOutlet weak var toggleDateChanger: UIButton!

    @IBOutlet weak var hoursDial: TickDialView!
    @IBOutlet weak var minutesDial: TickDialView!
    @IBOutlet weak var secondsDial: TickDialView!

    @IBOutlet weak var toggleDateChangerSmallWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var toggleDateChangerFullWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var updateDateBottomLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var countdownContainerVerticalCenterConstraint: NSLayoutConstraint!
    @IBOutlet weak var countdownContainerVerticalTopConstraint: NSLayoutConstraint!

    private let formatter = DateFormatter()
    private let defaults = UserDefaults.standard
    private let componentSet: Set<Calendar.Component> = [.day, .hour, .minute, .second]

    private var countdownDate = Date()
    private var datePickerContainerOpen = false
    private var timer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()

        formatter.dateStyle = .medium

        datePicker.datePickerMode = .date
        datePicker.minimumDate = Date()
        // Keep the classic spinning wheels the original layout was built around,
        // rather than the compact/inline pickers that became the default later.
        if #available(iOS 13.4, *) {
            datePicker.preferredDatePickerStyle = .wheels
        }

        // One dial per unit; the ring count matches the unit's range.
        hoursDial.total = 24
        minutesDial.total = 60
        secondsDial.total = 60

        // Restore a previously chosen date, if there is one.
        if let saved = defaults.object(forKey: "date") as? Date {
            countdownDate = saved
            datePicker.date = saved
        } else {
            countdownDate = datePicker.date
        }

        updateDifferenceLabels()

        timer = Timer.scheduledTimer(timeInterval: 1.0,
                                     target: self,
                                     selector: #selector(updateDifferenceLabels),
                                     userInfo: nil,
                                     repeats: true)

        closeDatePicker()
    }

    @IBAction func toggleDateChangerClicked(_ sender: Any) {
        if datePickerContainerOpen {
            closeDatePicker()
        } else {
            openDatePicker()
        }
    }

    @IBAction func chooseNewDate(_ sender: Any) {
        countdownDate = datePicker.date
        defaults.set(countdownDate, forKey: "date")
        updateDifferenceLabels()
        closeDatePicker()
        updateBadge()
    }

    private func updateBadge() {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: countdownDate).day ?? 0
        let count = max(0, days)
        if #available(iOS 16.0, *) {
            UNUserNotificationCenter.current().setBadgeCount(count)
        } else {
            UIApplication.shared.applicationIconBadgeNumber = count
        }
    }

    private func openDatePicker() {
        UIView.animate(withDuration: 0.3, animations: {
            self.toggleDateChanger.contentHorizontalAlignment = .center
            self.toggleDateChanger.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            self.toggleDateChanger.setTitle("✕", for: .normal)
            self.toggleDateChangerSmallWidthConstraint.priority = UILayoutPriority(750)
            self.toggleDateChangerFullWidthConstraint.priority = UILayoutPriority(250)
            self.updateDateBottomLayoutConstraint.constant = 0
            self.countdownContainerVerticalCenterConstraint.priority = UILayoutPriority(250)
            self.countdownContainerVerticalTopConstraint.priority = UILayoutPriority(750)

            self.view.layoutIfNeeded()
            self.datePicker.alpha = 1
        }, completion: { _ in
            self.datePickerContainerOpen = true
        })
    }

    private func closeDatePicker() {
        UIView.animate(withDuration: 0.3, animations: {
            self.datePicker.alpha = 0

            self.toggleDateChanger.contentHorizontalAlignment = .left
            self.toggleDateChanger.contentEdgeInsets = UIEdgeInsets(top: 0, left: 32, bottom: 16, right: 0)
            self.toggleDateChanger.setTitle(self.formatter.string(from: self.datePicker.date), for: .normal)
            self.toggleDateChangerSmallWidthConstraint.priority = UILayoutPriority(250)
            self.toggleDateChangerFullWidthConstraint.priority = UILayoutPriority(750)
            self.updateDateBottomLayoutConstraint.constant = -160
            self.countdownContainerVerticalCenterConstraint.priority = UILayoutPriority(750)
            self.countdownContainerVerticalTopConstraint.priority = UILayoutPriority(250)

            self.view.layoutIfNeeded()
        }, completion: { _ in
            self.datePickerContainerOpen = false
        })
    }

    @objc private func updateDifferenceLabels() {
        let now = Date()
        let components = Calendar.current.dateComponents(componentSet, from: now, to: countdownDate)

        let days = max(0, components.day ?? 0)
        let hours = max(0, components.hour ?? 0)
        let minutes = max(0, components.minute ?? 0)
        let seconds = max(0, components.second ?? 0)

        daysLeftlabel.text = "\(days) Days Left"
        hoursLeftLabel.text = "\(hours)"
        minutesLeftLabel.text = "\(minutes)"
        secondsLeftLabel.text = "\(seconds)"

        hoursDial.value = hours
        minutesDial.value = minutes
        secondsDial.value = seconds
    }
}
