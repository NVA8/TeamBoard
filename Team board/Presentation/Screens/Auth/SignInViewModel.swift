import Combine
import Foundation

@MainActor
final class SignInViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let environment: AppEnvironment
    var onSignedIn: (() -> Void)?

    init(environment: AppEnvironment) {
        self.environment = environment
    }

    func signIn() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Введите email и пароль."
            return
        }
        _Concurrency.Task {
            isLoading = true
            defer { isLoading = false }
            do {
                _ = try await environment.signInEmailUseCase.execute(email: email, password: password)
                await MainActor.run {
                    errorMessage = nil
                    onSignedIn?()
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
