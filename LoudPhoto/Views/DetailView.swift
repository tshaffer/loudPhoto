import SwiftUI
import UIKit

struct DetailView: View {
    let item: CaptureItem

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
    }
}
