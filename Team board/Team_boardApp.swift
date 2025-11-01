//
//  Team_boardApp.swift
//  Team board
//
//  Created by Валерий Никитин on 01.11.2025.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

@main
struct Team_boardApp: App {
#if canImport(UIKit)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
#endif

    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
    }
}

#if canImport(UIKit)
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseConfigurationService.shared.configureIfNeeded()
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        _Concurrency.Task {
            try? await AppEnvironment().notificationRepository.updateDeviceToken(deviceToken)
        }
    }
}
#endif
