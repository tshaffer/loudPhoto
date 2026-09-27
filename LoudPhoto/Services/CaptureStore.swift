import Foundation

final class CaptureStore: ObservableObject {
    static let shared = CaptureStore()

    @Published private(set) var items: [CaptureItem] = []

    private let fileManager = FileManager.default

    private lazy var capturesDirectory: URL = {
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = documents.appendingPathComponent("Captures", isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }()

    private init() {
        loadItems()
    }

    func url(for filename: String) -> URL {
        capturesDirectory.appendingPathComponent(filename)
    }

    func loadItems() {
        let jsonFiles = (try? fileManager.contentsOfDirectory(at: capturesDirectory, includingPropertiesForKeys: nil))?
            .filter { $0.pathExtension == "json" } ?? []

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let loaded = jsonFiles.compactMap { url -> CaptureItem? in
            guard let data = try? Data(contentsOf: url) else { return nil }
            return try? decoder.decode(CaptureItem.self, from: data)
        }

        items = loaded.sorted { $0.dateCreated > $1.dateCreated }
    }

    @discardableResult
    func saveNewCapture(photoData: Data, configuredDuration: Double) -> CaptureItem {
        let id = UUID()
        let photoFilename = "\(id.uuidString).jpg"
        try? photoData.write(to: url(for: photoFilename))

        let item = CaptureItem(
            id: id,
            dateCreated: Date(),
            configuredDurationSeconds: configuredDuration,
            audioDurationSeconds: nil,
            photoFilename: photoFilename,
            audioFilename: nil
        )
        writeMetadata(item)
        items.insert(item, at: 0)
        return item
    }

    func attachAudio(to item: CaptureItem, audioURL: URL, actualDuration: Double) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        let audioFilename = "\(item.id.uuidString).m4a"
        let destination = url(for: audioFilename)
        try? fileManager.removeItem(at: destination)
        try? fileManager.moveItem(at: audioURL, to: destination)

        var updated = items[index]
        updated.audioFilename = audioFilename
        updated.audioDurationSeconds = actualDuration
        items[index] = updated
        writeMetadata(updated)
    }

    func delete(_ item: CaptureItem) {
        try? fileManager.removeItem(at: url(for: item.photoFilename))
        if let audioFilename = item.audioFilename {
            try? fileManager.removeItem(at: url(for: audioFilename))
        }
        try? fileManager.removeItem(at: url(for: "\(item.id.uuidString).json"))
        items.removeAll { $0.id == item.id }
    }

    private func writeMetadata(_ item: CaptureItem) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(item) else { return }
        try? data.write(to: url(for: "\(item.id.uuidString).json"))
    }
}
