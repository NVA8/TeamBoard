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
        NavigationStack {
            Group {
                switch coordinator.activeScreen {
                case .authentication:
                    SignInView(viewModel: SignInViewModel(environment: environment))
                case .main:
                    MainTabView(coordinator: coordinator, environment: environment)
                }
            }
        }
        .task { coordinator.handleLaunch() }
        .environmentObject(environment)
        .environmentObject(coordinator)
    }
}
