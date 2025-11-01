import Foundation
import SwiftUI

enum AppScreen: Hashable {
    case authentication
    case main
}

@MainActor
final class AppCoordinator: ObservableObject {
    @Published var path: [AppScreen] = []
    @Published var currentTab: MainTab = .boards

    private let environment: AppEnvironment

    init(environment: AppEnvironment) {
        self.environment = environment
    }

    func handleLaunch() {
        FirebaseConfigurationService.shared.configureIfNeeded()
        _Concurrency.Task {
            if let user = try await environment.observeCurrentUserUseCase.execute(), user.isActive {
                path = [.main]
            } else {
                path = [.authentication]
            }
        }
    }

    func signOut() {
        _Concurrency.Task {
            try? await environment.signOutUseCase.execute()
            await MainActor.run {
                path = [.authentication]
            }
        }
    }
}

enum MainTab: Hashable {
    case boards
    case chat
    case analytics
    case settings
}
