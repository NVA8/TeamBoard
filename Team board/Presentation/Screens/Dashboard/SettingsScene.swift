import SwiftUI

struct SettingsScene: View {
    @ObservedObject var coordinator: AppCoordinator
    @ObservedObject var environment: AppEnvironment
    @State private var biometricsEnabled = true
    @State private var notificationsEnabled = true

    var body: some View {
        NavigationStack {
            Form {
                Section("Безопасность") {
                    Toggle("FaceID / TouchID", isOn: $biometricsEnabled)
                    Button("Запросить биометрическую проверку") {
                        BiometricGatekeeper().evaluate(reason: "Подтвердите личность для доступа к данным.")
                    }
                }

                Section("Уведомления") {
                    Toggle("Push-уведомления", isOn: $notificationsEnabled)
                        .onChange(of: notificationsEnabled) { isOn in
                            _Concurrency.Task {
                                if isOn {
                                    try? await environment.notificationRepository.registerForPushNotifications()
                                }
                            }
                        }
                }

                Section("Сессия") {
                    Button(role: .destructive) {
                        coordinator.signOut()
                    } label: {
                        Text("Выйти")
                    }
                }
            }
            .navigationTitle("Настройки")
        }
    }
}

#Preview {
    SettingsScene(coordinator: AppCoordinator(environment: AppEnvironment()), environment: AppEnvironment())
}
