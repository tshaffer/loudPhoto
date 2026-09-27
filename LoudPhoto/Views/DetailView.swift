import SwiftUI
import UIKit

struct DetailView: View {
    let item: CaptureItem
    @State private var shareItem: IdentifiableURL?
    @State private var isExporting = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let image = UIImage(contentsOfFile: CaptureStore.shared.url(for: item.photoFilename).path) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                }

                Text(item.dateCreated.formatted(date: .abbreviated, time: .shortened))
                    .font(.headline)
                    .padding(.horizontal)

                if item.hasAudio, let audioFilename = item.audioFilename {
                    AudioPlaybackView(
                        audioURL: CaptureStore.shared.url(for: audioFilename),
                        duration: item.audioDurationSeconds ?? 0
                    )
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Capture")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    exportItem()
                } label: {
                    if isExporting {
                        ProgressView()
                    } else {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
                .disabled(isExporting)
            }
        }
        .sheet(item: $shareItem) { item in
            ShareSheet(activityItems: [item.url])
        }
    }

    private func exportItem() {
        isExporting = true
        DispatchQueue.global(qos: .userInitiated).async {
            let zipURL = CaptureExporter.makeZip(for: [item])
            DispatchQueue.main.async {
                isExporting = false
                if let zipURL {
                    shareItem = IdentifiableURL(url: zipURL)
                }
            }
        }
    }
}
