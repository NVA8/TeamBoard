import Foundation
import UserNotifications
#if canImport(UIKit)
import UIKit
#endif

final class PushNotificationRepository: NSObject, NotificationRepository, UNUserNotificationCenterDelegate {
    private let center: UNUserNotificationCenter

    override init() {
        center = UNUserNotificationCenter.current()
        super.init()
        center.delegate = self
    }

    func registerForPushNotifications() async throws {
        let settings = try await center.requestAuthorization(options: [.alert, .badge, .sound])
        guard settings else {
            throw RepositoryError.featureUnavailable
        }
#if canImport(UIKit)
        await MainActor.run {
            UIApplication.shared.registerForRemoteNotifications()
        }
#endif
    }

    func updateDeviceToken(_ token: Data) async throws {
        // Upload token to backend (e.g., Firestore `deviceTokens` collection).
        // Keeping it as a placeholder since networking depends on environment.
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
}
