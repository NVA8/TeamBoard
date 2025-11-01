import SwiftUI

struct SettingsScene: View {
    @ObservedObject var coordinator: AppCoordinator
    @ObservedObject var environment: AppEnvironment
    @State private var biometricsEnabled = true
    @State private var notificationsEnabled = true

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color(.systemGray6),
                        Color(.systemTeal).opacity(0.12)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        header

                        SettingsCard(title: "Безопасность", icon: "lock.shield", tint: .indigo) {
                            Toggle("FaceID / TouchID", isOn: $biometricsEnabled)
                                .toggleStyle(SwitchToggleStyle(tint: .indigo))

                            Button {
                                BiometricGatekeeper().evaluate(reason: "Подтвердите личность для доступа к данным.")
                            } label: {
                                Label("Запросить проверку", systemImage: "faceid")
                                    .fontWeight(.semibold)
                            }
                        }

                        SettingsCard(title: "Уведомления", icon: "bell.badge", tint: .orange) {
                            Toggle("Push-уведомления", isOn: $notificationsEnabled)
                                .toggleStyle(SwitchToggleStyle(tint: .orange))
                                .onChange(of: notificationsEnabled) { isOn in
                                    _Concurrency.Task {
                                        if isOn {
                                            try? await environment.notificationRepository.registerForPushNotifications()
                                        }
                                    }
                                }
                            Text("Включите, чтобы мгновенно получать апдейты по задачам и упоминаниям.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }

                        SettingsCard(title: "Сессия", icon: "rectangle.portrait.and.arrow.right", tint: .red) {
                            Button(role: .destructive) {
                                coordinator.signOut()
                            } label: {
                                Label("Выйти из аккаунта", systemImage: "arrow.uturn.left")
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Настройки")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Управление доступом")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("Настройки профиля и оповещений")
                .font(.largeTitle.bold())
            Text("Настройте безопасность, уведомления и завершайте работу в один клик.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.08), radius: 20, y: 14)
        )
    }
}

private struct SettingsCard<Content: View>: View {
    let title: String
    let icon: String
    let tint: Color
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(Circle().fill(tint.gradient))
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            VStack(alignment: .leading, spacing: 16) {
                content
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(.thinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.35), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.05), radius: 16, y: 10)
    }

    private var subtitle: String {
        switch title {
        case "Безопасность":
            return "Защитите корпоративные данные биометрией."
        case "Уведомления":
            return "Контролируйте вовлечённость команды."
        case "Сессия":
            return "Завершайте работу на всех устройствах."
        default:
            return ""
        }
    }
}

#Preview {
    SettingsScene(coordinator: AppCoordinator(environment: AppEnvironment()), environment: AppEnvironment())
}
