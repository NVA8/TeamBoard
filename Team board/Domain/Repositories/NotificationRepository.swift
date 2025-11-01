import Foundation

public protocol NotificationRepository: Sendable {
    func registerForPushNotifications() async throws
    func updateDeviceToken(_ token: Data) async throws
}

