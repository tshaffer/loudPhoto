import SwiftUI
import UIKit

struct GalleryView: View {
    @ObservedObject private var store = CaptureStore.shared
    @State private var isSelecting = false
    @State private var selectedIDs: Set<UUID> = []
    @State private var shareItem: IdentifiableURL?
    @State private var isExporting = false

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
                        cell(for: item)
                    }
                }
            }
            .navigationTitle("Library")
            .navigationDestination(for: CaptureItem.self) { item in
                DetailView(item: item)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isSelecting ? "Done" : "Select") {
                        isSelecting.toggle()
                        if !isSelecting { selectedIDs.removeAll() }
                    }
                    .disabled(store.items.isEmpty)
                }
            }
            .safeAreaInset(edge: .bottom) {
                if isSelecting {
                    selectionBar
                }
            }
            .onAppear { store.loadItems() }
            .sheet(item: $shareItem) { item in
                ShareSheet(activityItems: [item.url])
            }
        }
    }

    private var selectionBar: some View {
        HStack {
            Text("\(selectedIDs.count) selected")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Button {
                exportSelection()
            } label: {
                if isExporting {
                    ProgressView()
                } else {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
            }
            .disabled(selectedIDs.isEmpty || isExporting)
        }
        .padding()
        .background(.bar)
    }

    @ViewBuilder
    private func cell(for item: CaptureItem) -> some View {
        let selected = selectedIDs.contains(item.id)

        if isSelecting {
            ThumbnailCell(item: item, isSelected: selected)
                .onTapGesture { toggleSelection(item.id) }
        } else {
            NavigationLink(value: item) {
                ThumbnailCell(item: item, isSelected: false)
            }
            .buttonStyle(.plain)
        }
    }

    private func toggleSelection(_ id: UUID) {
        if selectedIDs.contains(id) {
            selectedIDs.remove(id)
        } else {
            selectedIDs.insert(id)
        }
    }

    private func exportSelection() {
        let items = store.items.filter { selectedIDs.contains($0.id) }
        guard !items.isEmpty else { return }
        isExporting = true
        DispatchQueue.global(qos: .userInitiated).async {
            let zipURL = CaptureExporter.makeZip(for: items)
            DispatchQueue.main.async {
                isExporting = false
                if let zipURL {
                    shareItem = IdentifiableURL(url: zipURL)
                }
            }
        }
    }
}

private struct ThumbnailCell: View {
    let item: CaptureItem
    var isSelected: Bool = false

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

                if isSelected {
                    Color.black.opacity(0.25)
                        .frame(width: geo.size.width, height: geo.size.width)
                }
            }
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .orange)
                        .font(.title3)
                        .padding(6)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}
