import AVFoundation

final class AudioCaptureService: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var elapsed: TimeInterval = 0

    private var recorder: AVAudioRecorder?
    private var timer: Timer?
    private var configuredDuration: TimeInterval = 10
    private var completion: ((URL?, TimeInterval) -> Void)?

    /// Starts recording immediately, for up to `duration` seconds. Call
    /// `stopEarly()` to interrupt before that (mirrors Spectre's
    /// tap-shutter-again-to-stop pattern).
    func start(duration: TimeInterval, completion: @escaping (URL?, TimeInterval) -> Void) {
        configuredDuration = duration
        self.completion = completion

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, options: [.defaultToSpeaker])
            try session.setActive(true)
        } catch {
            completion(nil, 0)
            return
        }

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".m4a")
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            let recorder = try AVAudioRecorder(url: tempURL, settings: settings)
            recorder.delegate = self
            recorder.record(forDuration: duration)
            self.recorder = recorder
            isRecording = true
            elapsed = 0
            startTimer()
        } catch {
            completion(nil, 0)
        }
    }

    func stopEarly() {
        guard isRecording else { return }
        recorder?.stop()
    }

    private func startTimer() {
        timer?.invalidate()
        let startDate = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.elapsed = min(Date().timeIntervalSince(startDate), self.configuredDuration)
        }
    }

    private func finish(success: Bool) {
        timer?.invalidate()
        timer = nil
        isRecording = false
        let url = success ? recorder?.url : nil
        let duration = elapsed
        recorder = nil
        completion?(url, duration)
        completion = nil
    }
}

extension AudioCaptureService: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        finish(success: flag)
    }
}
