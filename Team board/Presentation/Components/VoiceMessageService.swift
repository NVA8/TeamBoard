import Foundation
#if canImport(AVFoundation)
import AVFoundation
#endif
#if canImport(Speech)
import Speech
#endif

@MainActor
final class VoiceMessageService: NSObject, ObservableObject {
    enum RecordingState: Equatable {
        case idle
        case recording
        case processing
        case failed(String)
    }

    struct Result {
        let fileURL: URL
        let duration: TimeInterval
        let transcript: String?
    }

    @Published private(set) var state: RecordingState = .idle
    @Published private(set) var currentDuration: TimeInterval = 0

#if canImport(AVFoundation)
    private var recorder: AVAudioRecorder?
    private var timer: Timer?
#endif
#if canImport(Speech)
    private var recognitionTask: SFSpeechRecognitionTask?
#endif

    func startRecording() async throws {
#if canImport(AVFoundation) && canImport(Speech)
        guard state == .idle else { return }
        state = .processing
        do {
            try await ensurePermissions()
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true, options: .notifyOthersOnDeactivation)

            let fileURL = makeRecordingURL()
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44_100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            recorder = try AVAudioRecorder(url: fileURL, settings: settings)
            recorder?.isMeteringEnabled = true
            recorder?.record()

            currentDuration = 0
            startTimer()
            state = .recording
        } catch {
            state = .failed(error.localizedDescription)
            throw error
        }
#else
        state = .failed("Voice recording недоступна на этой платформе.")
        throw VoiceMessageError.featureUnavailable
#endif
    }

    func stopRecording() async throws -> Result {
#if canImport(AVFoundation) && canImport(Speech)
        guard state == .recording, let recorder else {
            throw VoiceMessageError.notRecording
        }
        state = .processing
        stopTimer()
        recorder.stop()
        let duration = currentDuration
        let url = recorder.url
        self.recorder = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        do {
            let transcript = try await transcribeAudio(at: url)
            state = .idle
            currentDuration = 0
            return Result(fileURL: url, duration: duration, transcript: transcript)
        } catch {
            state = .failed(error.localizedDescription)
            currentDuration = 0
            throw error
        }
#else
        throw VoiceMessageError.featureUnavailable
#endif
    }

    func cancelRecording() {
#if canImport(AVFoundation)
        stopTimer()
        recorder?.stop()
        if let url = recorder?.url {
            try? FileManager.default.removeItem(at: url)
        }
        recorder = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
#endif
#if canImport(Speech)
        recognitionTask?.cancel()
        recognitionTask = nil
#endif
        currentDuration = 0
        state = .idle
    }

#if canImport(AVFoundation) && canImport(Speech)
    private func ensurePermissions() async throws {
        let audioGranted = await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
        guard audioGranted else { throw VoiceMessageError.microphonePermissionDenied }

        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
        guard speechStatus == .authorized else { throw VoiceMessageError.speechPermissionDenied }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            guard let self else { return }
            currentDuration += 0.2
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func makeRecordingURL() -> URL {
        let fileName = "voice-note-\(UUID().uuidString).m4a"
        return FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
    }

    private func transcribeAudio(at url: URL) async throws -> String? {
        guard let recognizer = SFSpeechRecognizer() else {
            throw VoiceMessageError.featureUnavailable
        }
        if !recognizer.isAvailable {
            return nil
        }
        let request = SFSpeechURLRecognitionRequest(url: url)
        request.shouldReportPartialResults = false
        return try await withCheckedThrowingContinuation { continuation in
            var didResume = false
            self.recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
                guard let self else { return }
                if let error {
                    guard !didResume else { return }
                    didResume = true
                    self.recognitionTask = nil
                    continuation.resume(throwing: error)
                    return
                }
                if let result, result.isFinal {
                    guard !didResume else { return }
                    didResume = true
                    self.recognitionTask = nil
                    continuation.resume(returning: result.bestTranscription.formattedString)
                } else if result == nil {
                    guard !didResume else { return }
                    didResume = true
                    self.recognitionTask = nil
                    continuation.resume(returning: nil)
                }
            }
        }
    }
#endif
}

enum VoiceMessageError: LocalizedError {
    case featureUnavailable
    case microphonePermissionDenied
    case speechPermissionDenied
    case notRecording

    var errorDescription: String? {
        switch self {
        case .featureUnavailable:
            return "Голосовые сообщения не поддерживаются на этом устройстве."
        case .microphonePermissionDenied:
            return "Нет доступа к микрофону. Разрешите использование микрофона в настройках."
        case .speechPermissionDenied:
            return "Нет доступа к распознаванию речи."
        case .notRecording:
            return "Запись еще не начата."
        }
    }
}
