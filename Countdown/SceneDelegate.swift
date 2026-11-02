//
//  SceneDelegate.swift
//  Countdown
//
//  Owns the app's single window. iOS 27 requires the UIScene lifecycle (an app
//  that builds its window in the app delegate is trapped at launch), so the
//  window is created here from the connecting `UIWindowScene`. The scene is
//  declared in Info.plist under `UIApplicationSceneManifest`.
//

import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        // The screen is built entirely in code (no storyboard).
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = CountdownViewController()
        window.makeKeyAndVisible()
        self.window = window
    }
}
