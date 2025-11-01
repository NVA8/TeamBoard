import SwiftUI

struct MainTabView: View {
    @ObservedObject var coordinator: AppCoordinator
    @ObservedObject var environment: AppEnvironment

    var body: some View {
        TabView(selection: $coordinator.currentTab) {
            BoardsScene(viewModel: BoardsViewModel(environment: environment))
                .tabItem {
                    Label("Доски", systemImage: "square.grid.3x3")
                }
                .tag(MainTab.boards)

            ChatScene(viewModel: ChatViewModel(environment: environment))
                .tabItem {
                    Label("Чат", systemImage: "bubble.left.and.bubble.right")
                }
                .tag(MainTab.chat)

            AnalyticsScene(viewModel: AnalyticsViewModel(environment: environment))
                .tabItem {
                    Label("Аналитика", systemImage: "chart.bar.xaxis")
                }
                .tag(MainTab.analytics)

            SettingsScene(coordinator: coordinator, environment: environment)
                .tabItem {
                    Label("Настройки", systemImage: "gear")
                }
                .tag(MainTab.settings)
        }
    }
}

#Preview {
    MainTabView(
        coordinator: AppCoordinator(environment: AppEnvironment()),
        environment: AppEnvironment()
    )
}

