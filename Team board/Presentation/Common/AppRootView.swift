import SwiftUI

struct AppRootView: View {
    @StateObject private var environment = AppEnvironment()
    @StateObject private var coordinator: AppCoordinator

    init() {
        let env = AppEnvironment()
        _environment = StateObject(wrappedValue: env)
        _coordinator = StateObject(wrappedValue: AppCoordinator(environment: env))
    }

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            Color.clear
                .task { coordinator.handleLaunch() }
                .navigationDestination(for: AppScreen.self) { screen in
                    switch screen {
                    case .authentication:
                        SignInView(viewModel: SignInViewModel(environment: environment))
                    case .main:
                        MainTabView(coordinator: coordinator, environment: environment)
                    }
                }
        }
        .environmentObject(environment)
        .environmentObject(coordinator)
    }
}

