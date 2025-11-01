import Foundation
import SwiftUI

enum AppScreen: Hashable {
    case authentication
    case main
}

@MainActor
final class AppCoordinator: ObservableObject {
    @Published var activeScreen: AppScreen = .authentication
    @Published var currentTab: MainTab = .boards

    private let environment: AppEnvironment

    init(environment: AppEnvironment) {
        self.environment = environment
    }

    func showAuthentication() {
        activeScreen = .authentication
    }

    func showMain() {
        currentTab = .boards
        activeScreen = .main
    }

    func handleLaunch() {
        FirebaseConfigurationService.shared.configureIfNeeded()
        _Concurrency.Task {
            if let user = try await environment.observeCurrentUserUseCase.execute(), user.isActive {
                await MainActor.run { self.showMain() }
            } else {
                await MainActor.run { self.showAuthentication() }
            }
        }
    }

    func signOut() {
        _Concurrency.Task {
            try? await environment.signOutUseCase.execute()
            await MainActor.run { self.showAuthentication() }
        }
    }
}

enum MainTab: Hashable {
    case boards
    case chat
    case analytics
    case settings
}
