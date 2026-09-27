import SwiftUI
import UIKit

struct GalleryView: View {
    @ObservedObject private var store = CaptureStore.shared
    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 2) {
                    ForEach(store.items) { item in
                        NavigationLink(value: item) {
                            ThumbnailCell(item: item)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("Library")
            .navigationDestination(for: CaptureItem.self) { item in
                DetailView(item: item)
            }
            .onAppear { store.loadItems() }
        }
    }
}

private struct ThumbnailCell: View {
    let item: CaptureItem

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottomTrailing) {
                if let image = UIImage(contentsOfFile: CaptureStore.shared.url(for: item.photoFilename).path) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.width)
                        .clipped()
                } else {
                    Color.gray.opacity(0.2)
                        .frame(width: geo.size.width, height: geo.size.width)
                }

                if item.hasAudio {
                    HStack(spacing: 2) {
                        Image(systemName: "waveform")
                        Text("\(Int(item.audioDurationSeconds ?? 0))s")
                    }
                    .font(.caption2).bold()
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6).padding(.vertical, 3)
                    .background(.black.opacity(0.55), in: Capsule())
                    .padding(6)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}
