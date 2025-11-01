import Foundation
#if canImport(LocalAuthentication)
import LocalAuthentication
#endif

struct BiometricGatekeeper {
    func evaluate(reason: String) {
#if canImport(LocalAuthentication)
        let context = LAContext()
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
                if let error {
                    print("Biometric error: \(error.localizedDescription)")
                } else {
                    print("Biometric success: \(success)")
                }
            }
        } else if let error {
            print("Biometrics unavailable: \(error.localizedDescription)")
        }
#endif
    }
}

