import AVFoundation
import UIKit

final class CameraService: NSObject, ObservableObject {
    let session = AVCaptureSession()

    @Published var isSessionRunning = false
    @Published var zoomFactor: CGFloat = 1.0
    @Published var flashMode: AVCaptureDevice.FlashMode = .auto
    @Published var currentPosition: AVCaptureDevice.Position = .back

    private let photoOutput = AVCapturePhotoOutput()
    private var videoDeviceInput: AVCaptureDeviceInput?
    private let sessionQueue = DispatchQueue(label: "com.tedshaffer.loudphoto.session")

    private var photoCaptureCompletion: ((Data?) -> Void)?

    override init() {
        super.init()
        configureSession()
    }

    func start() {
        sessionQueue.async {
            if !self.session.isRunning {
                self.session.startRunning()
                DispatchQueue.main.async { self.isSessionRunning = true }
            }
        }
    }

    func stop() {
        sessionQueue.async {
            if self.session.isRunning {
                self.session.stopRunning()
                DispatchQueue.main.async { self.isSessionRunning = false }
            }
        }
    }

    private func configureSession() {
        sessionQueue.async {
            self.session.beginConfiguration()
            self.session.sessionPreset = .photo

            if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
               let input = try? AVCaptureDeviceInput(device: device),
               self.session.canAddInput(input) {
                self.session.addInput(input)
                self.videoDeviceInput = input
            }

            if self.session.canAddOutput(self.photoOutput) {
                self.session.addOutput(self.photoOutput)
            }

            self.session.commitConfiguration()
        }
    }

    func capturePhoto(completion: @escaping (Data?) -> Void) {
        photoCaptureCompletion = completion
        let settings = AVCapturePhotoSettings()
        settings.flashMode = flashMode
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    func setZoom(_ factor: CGFloat) {
        guard let device = videoDeviceInput?.device else { return }
        let clamped = min(max(factor, 1.0), device.activeFormat.videoMaxZoomFactor)
        do {
            try device.lockForConfiguration()
            device.videoZoomFactor = clamped
            device.unlockForConfiguration()
            DispatchQueue.main.async { self.zoomFactor = clamped }
        } catch {
            // ignore — zoom is best-effort
        }
    }

    func flipCamera() {
        sessionQueue.async {
            guard let currentInput = self.videoDeviceInput else { return }
            self.session.beginConfiguration()
            self.session.removeInput(currentInput)

            let newPosition: AVCaptureDevice.Position = self.currentPosition == .back ? .front : .back
            if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition),
               let newInput = try? AVCaptureDeviceInput(device: device),
               self.session.canAddInput(newInput) {
                self.session.addInput(newInput)
                self.videoDeviceInput = newInput
                DispatchQueue.main.async {
                    self.currentPosition = newPosition
                    self.zoomFactor = 1.0
                }
            } else {
                self.session.addInput(currentInput)
            }

            self.session.commitConfiguration()
        }
    }
}

extension CameraService: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        let data = photo.fileDataRepresentation()
        DispatchQueue.main.async {
            self.photoCaptureCompletion?(data)
            self.photoCaptureCompletion = nil
        }
    }
}
