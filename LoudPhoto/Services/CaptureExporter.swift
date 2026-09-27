import Foundation
import ZIPFoundation

/// Bundles one or more captures (photo + audio + metadata) into a single
/// .zip for sharing — each capture gets its own subfolder inside the zip
/// so photo/audio/metadata stay together as one unit through AirDrop,
/// Messages, Files, etc., however many captures are selected at once.
///
/// Filenames are self-describing (timestamp + short UUID) rather than
/// generic "photo.jpg"/"audio.m4a", so a capture's files stay unambiguous
/// even if something downstream flattens the folder structure.
enum CaptureExporter {
    private static let filenameFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        formatter.timeZone = TimeZone.current
        return formatter
    }()

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

                let baseName = "\(filenameFormatter.string(from: item.dateCreated))_\(item.id.uuidString.prefix(8))"

                let photoSource = store.url(for: item.photoFilename)
                if fileManager.fileExists(atPath: photoSource.path) {
                    let photoExtension = (item.photoFilename as NSString).pathExtension
                    try fileManager.copyItem(at: photoSource, to: itemDir.appendingPathComponent("\(baseName).\(photoExtension)"))
                }

                if let audioFilename = item.audioFilename {
                    let audioSource = store.url(for: audioFilename)
                    if fileManager.fileExists(atPath: audioSource.path) {
                        let audioExtension = (audioFilename as NSString).pathExtension
                        try fileManager.copyItem(at: audioSource, to: itemDir.appendingPathComponent("\(baseName).\(audioExtension)"))
                    }
                }

                let metadataData = try encoder.encode(item)
                try metadataData.write(to: itemDir.appendingPathComponent("\(baseName).json"))
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
