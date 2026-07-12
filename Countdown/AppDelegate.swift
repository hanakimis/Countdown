//
//  AppDelegate.swift
//  Countdown
//
//  Created by Hana Kim on 3/9/15.
//  Copyright (c) 2015 Hana Kim. All rights reserved.
//

import UIKit
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Ask permission to show the days-remaining count on the app icon badge.
        // Skipped during automated screenshots so the system alert doesn't cover
        // the UI (set via SIMCTL_CHILD_SCREENSHOTS=1).
        if ProcessInfo.processInfo.environment["SCREENSHOTS"] == nil {
            UNUserNotificationCenter.current().requestAuthorization(options: [.badge]) { _, _ in }
        }
        return true
    }
}
