import SwiftUI
import AVFoundation

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    var currentZoom: () -> CGFloat
    var onPinchZoom: (CGFloat) -> Void

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill

        let pinch = UIPinchGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handlePinch(_:))
        )
        view.addGestureRecognizer(pinch)
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(currentZoom: currentZoom, onPinchZoom: onPinchZoom)
    }

    final class Coordinator: NSObject {
        let currentZoom: () -> CGFloat
        let onPinchZoom: (CGFloat) -> Void
        private var baseZoom: CGFloat = 1.0

        init(currentZoom: @escaping () -> CGFloat, onPinchZoom: @escaping (CGFloat) -> Void) {
            self.currentZoom = currentZoom
            self.onPinchZoom = onPinchZoom
        }

        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            switch gesture.state {
            case .began:
                baseZoom = currentZoom()
            case .changed:
                onPinchZoom(baseZoom * gesture.scale)
            default:
                break
            }
        }
    }

    final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            layer as! AVCaptureVideoPreviewLayer
        }
    }
}
