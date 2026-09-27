import SwiftUI
import UIKit

/// Identifiable wrapper so a plain URL can drive a `.sheet(item:)` presentation.
struct IdentifiableURL: Identifiable {
    let url: URL
    var id: String { url.absoluteString }
}

/// Thin SwiftUI wrapper around the standard iOS share sheet (AirDrop,
/// Messages, Save to Files, etc.) — used for sharing exported capture zips.
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
