import SwiftUI
#if canImport(AVFoundation)
import AVFoundation
#endif

struct VoiceMessagePlayerView: View {
    let url: URL
    let duration: TimeInterval

    @StateObject private var controller: VoiceMessagePlaybackController

    init(url: URL, duration: TimeInterval) {
        self.url = url
        self.duration = duration
        _controller = StateObject(wrappedValue: VoiceMessagePlaybackController(url: url, duration: duration))
    }

    var body: some View {
#if canImport(AVFoundation)
        HStack(spacing: 12) {
            Button {
                controller.togglePlayback()
            } label: {
                Image(systemName: controller.isPlaying ? "pause.fill" : "play.fill")
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(Circle().fill(.blue))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                ProgressView(value: controller.progress)
                    .progressViewStyle(.linear)
                Text(controller.formattedRemainingTime)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .onDisappear {
            controller.stop()
        }
#else
        Text("Аудио недоступно на этой платформе")
            .font(.footnote)
            .foregroundStyle(.secondary)
#endif
    }
}

#if canImport(AVFoundation)
final class VoiceMessagePlaybackController: NSObject, ObservableObject {
    @Published var isPlaying = false
    @Published var progress: Double = 0

    private let url: URL
    private let duration: TimeInterval
    private var player: AVPlayer?
    private var timeObserver: Any?

    init(url: URL, duration: TimeInterval) {
        self.url = url
        self.duration = duration
        super.init()
        preparePlayer()
    }

    deinit {
        removeObservers()
    }

    var formattedRemainingTime: String {
        let remaining = max(duration * (1 - progress), 0)
        let seconds = Int(remaining.rounded())
        let minutes = seconds / 60
        let rest = seconds % 60
        return String(format: "%02d:%02d", minutes, rest)
    }

    func togglePlayback() {
        isPlaying ? pause() : play()
    }

    func stop() {
        pause()
        player?.seek(to: .zero)
        progress = 0
    }

    private func play() {
        guard let player else { return }
        player.play()
        isPlaying = true
    }

    private func pause() {
        player?.pause()
        isPlaying = false
    }

    private func preparePlayer() {
        let asset = AVURLAsset(url: url)
        let item = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: item)
        addPeriodicTimeObserver()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePlaybackFinished),
            name: .AVPlayerItemDidPlayToEndTime,
            object: item
        )
    }

    private func addPeriodicTimeObserver() {
        guard let player else { return }
        let interval = CMTime(seconds: 0.2, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self else { return }
            let seconds = CMTimeGetSeconds(time)
            if duration > 0 {
                progress = min(max(seconds / duration, 0), 1)
            }
        }
    }

    nonisolated(unsafe) private func removeObservers() {
        if let observer = timeObserver, let player {
            player.removeTimeObserver(observer)
        }
        timeObserver = nil
        NotificationCenter.default.removeObserver(self)
    }

    @objc
    private func handlePlaybackFinished() {
        pause()
        player?.seek(to: .zero)
        progress = 0
    }
}
#endif
