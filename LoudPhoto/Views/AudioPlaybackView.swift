import SwiftUI
import AVFoundation

final class AudioPlayerController: NSObject, ObservableObject {
    @Published var isPlaying = false
    @Published var progress: Double = 0

    private var player: AVAudioPlayer?
    private var timer: Timer?

    func togglePlayback(url: URL) {
        if isPlaying {
            pause()
        } else {
            play(url: url)
        }
    }

    private func play(url: URL) {
        if player == nil {
            player = try? AVAudioPlayer(contentsOf: url)
            player?.delegate = self
        }
        player?.play()
        isPlaying = true
        startTimer()
    }

    private func pause() {
        player?.pause()
        isPlaying = false
        timer?.invalidate()
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self, let player = self.player, player.duration > 0 else { return }
            self.progress = player.currentTime / player.duration
        }
    }
}

extension AudioPlayerController: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        progress = 0
        timer?.invalidate()
    }
}

struct AudioPlaybackView: View {
    let audioURL: URL
    let duration: Double
    @StateObject private var controller = AudioPlayerController()

    var body: some View {
        HStack(spacing: 12) {
            Button {
                controller.togglePlayback(url: audioURL)
            } label: {
                Image(systemName: controller.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.orange)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.gray.opacity(0.25)).frame(height: 4)
                        Capsule().fill(Color.orange).frame(width: geo.size.width * controller.progress, height: 4)
                    }
                }
                .frame(height: 4)

                Text(String(format: "%.0fs", duration))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }
}
