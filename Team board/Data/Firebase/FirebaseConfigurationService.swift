import Foundation
#if canImport(FirebaseCore)
import FirebaseCore
#endif

/// Handles Firebase configuration at application launch.
struct FirebaseConfigurationService {
    static let shared = FirebaseConfigurationService()

    func configureIfNeeded() {
#if canImport(FirebaseCore)
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
#endif
    }
}

