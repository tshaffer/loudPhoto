import SwiftUI
import UIKit

struct CaptureView: View {
    @StateObject private var cameraService = CameraService()
    @StateObject private var audioService = AudioCaptureService()
    @ObservedObject private var store = CaptureStore.shared

    @AppStorage("audioDurationSeconds") private var audioDuration: Double = 10
    @State private var showSettings = false

    private let availableDurations: [Double] = [5, 10, 15]

    var body: some View {
        ZStack {
            CameraPreviewView(
                session: cameraService.session,
                currentZoom: { cameraService.zoomFactor },
                onPinchZoom: { cameraService.setZoom($0) }
            )
            .ignoresSafeArea()

            VStack {
                topBar
                Spacer()
                zoomIndicator
                bottomControls
            }
        }
        .onAppear { cameraService.start() }
        .onDisappear { cameraService.stop() }
        .sheet(isPresented: $showSettings) {
            SettingsView(audioDuration: $audioDuration)
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                cameraService.flashMode = cameraService.flashMode == .auto ? .off : .auto
            } label: {
                Image(systemName: cameraService.flashMode == .auto ? "bolt.badge.a" : "bolt.slash")
            }
            Spacer()
            Button { showSettings = true } label: {
                Image(systemName: "gearshape.fill")
            }
        }
        .font(.title2)
        .foregroundStyle(.white)
        .padding()
    }

    private var zoomIndicator: some View {
        Text(String(format: "%.1fx", cameraService.zoomFactor))
            .font(.caption).bold()
            .foregroundStyle(.white)
            .padding(.horizontal, 10).padding(.vertical, 4)
            .background(.black.opacity(0.4), in: Capsule())
            .padding(.bottom, 8)
    }

    private var bottomControls: some View {
        VStack(spacing: 16) {
            durationPicker

            HStack {
                thumbnailButton
                Spacer()
                ShutterButtonView(
                    isRecording: audioService.isRecording,
                    progress: audioDuration > 0 ? audioService.elapsed / audioDuration : 0,
                    onTap: handleShutterTap
                )
                Spacer()
                Button(action: cameraService.flipCamera) {
                    Image(systemName: "arrow.triangle.2.circlepath.camera")
                        .font(.title2)
                        .foregroundStyle(.white)
                }
            }
            .padding(.horizontal, 32)

            if audioService.isRecording {
                Text(recordingLabel)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .padding(.bottom, 24)
    }

    private var recordingLabel: String {
        String(format: "%.0f:%02.0f / %.0f:%02.0f · tap to stop",
               floor(audioService.elapsed / 60), audioService.elapsed.truncatingRemainder(dividingBy: 60),
               floor(audioDuration / 60), audioDuration.truncatingRemainder(dividingBy: 60))
    }

    private var durationPicker: some View {
        HStack(spacing: 8) {
            ForEach(availableDurations, id: \.self) { duration in
                Text("\(Int(duration))s")
                    .font(.caption).bold()
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(duration == audioDuration ? Color.orange : Color.white.opacity(0.15), in: Capsule())
                    .foregroundStyle(duration == audioDuration ? .black : .white)
                    .onTapGesture {
                        guard !audioService.isRecording else { return }
                        audioDuration = duration
                    }
            }
        }
        .opacity(audioService.isRecording ? 0.5 : 1.0)
    }

    private var thumbnailButton: some View {
        Group {
            if let latest = store.items.first,
               let image = UIImage(contentsOfFile: store.url(for: latest.photoFilename).path) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 44, height: 44)
            }
        }
    }

    private func handleShutterTap() {
        if audioService.isRecording {
            audioService.stopEarly()
            return
        }

        cameraService.capturePhoto { data, photoExtension in
            guard let data else { return }
            let item = store.saveNewCapture(photoData: data, photoExtension: photoExtension, configuredDuration: audioDuration)

            audioService.start(duration: audioDuration) { url, actualDuration in
                if let url {
                    store.attachAudio(to: item, audioURL: url, actualDuration: actualDuration)
                }
            }
        }
    }
}
