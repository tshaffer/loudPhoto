import Foundation

struct CaptureItem: Identifiable, Codable, Hashable {
    let id: UUID
    let dateCreated: Date
    let configuredDurationSeconds: Double
    var audioDurationSeconds: Double?
    let photoFilename: String
    var audioFilename: String?

    var hasAudio: Bool { audioFilename != nil }
}
