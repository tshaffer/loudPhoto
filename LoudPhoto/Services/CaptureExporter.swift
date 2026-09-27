import Foundation
import ZIPFoundation

/// Bundles one or more captures (photo + audio + metadata) into a single
/// .zip for sharing — each capture gets its own subfolder inside the zip
/// so photo/audio/metadata stay together as one unit through AirDrop,
/// Messages, Files, etc., however many captures are selected at once.
enum CaptureExporter {
    static func makeZip(for items: [CaptureItem]) -> URL? {
        guard !items.isEmpty else { return nil }

        let fileManager = FileManager.default
        let store = CaptureStore.shared

        let stagingDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)

        let zipName = items.count == 1
            ? "LoudPhoto_\(items[0].id.uuidString.prefix(8)).zip"
            : "LoudPhoto_\(items.count)_captures.zip"
        let zipURL = fileManager.temporaryDirectory.appendingPathComponent(zipName)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        do {
            try? fileManager.removeItem(at: zipURL)
            try fileManager.createDirectory(at: stagingDir, withIntermediateDirectories: true)

            for item in items {
                let itemDir = stagingDir.appendingPathComponent(item.id.uuidString, isDirectory: true)
                try fileManager.createDirectory(at: itemDir, withIntermediateDirectories: true)

                let photoSource = store.url(for: item.photoFilename)
                if fileManager.fileExists(atPath: photoSource.path) {
                    try fileManager.copyItem(at: photoSource, to: itemDir.appendingPathComponent("photo.jpg"))
                }

                if let audioFilename = item.audioFilename {
                    let audioSource = store.url(for: audioFilename)
                    if fileManager.fileExists(atPath: audioSource.path) {
                        try fileManager.copyItem(at: audioSource, to: itemDir.appendingPathComponent("audio.m4a"))
                    }
                }

                let metadataData = try encoder.encode(item)
                try metadataData.write(to: itemDir.appendingPathComponent("metadata.json"))
            }

            try fileManager.zipItem(at: stagingDir, to: zipURL, shouldKeepParent: false)
            try? fileManager.removeItem(at: stagingDir)

            return zipURL
        } catch {
            try? fileManager.removeItem(at: stagingDir)
            return nil
        }
    }
}
