import SwiftUI

/// Idle: plain round shutter button.
/// Recording: fills with a clockwise progress ring toward the configured
/// duration (Spectre Camera-style) — tapping again while it's filling
/// stops the recording early.
struct ShutterButtonView: View {
    var isRecording: Bool
    var progress: Double // 0...1
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.35), lineWidth: 4)
                    .frame(width: 74, height: 74)

                if isRecording {
                    Circle()
                        .trim(from: 0, to: max(0, min(progress, 1)))
                        .stroke(Color.orange, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 74, height: 74)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.1), value: progress)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white)
                        .frame(width: 24, height: 24)
                } else {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 62, height: 62)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
