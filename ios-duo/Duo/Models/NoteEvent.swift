import Foundation

/// A single recorded note, positioned relative to the start of its region.
nonisolated struct NoteEvent: Identifiable, Hashable, Codable, Sendable {
    var id: UUID = UUID()
    var pitch: UInt8
    var velocity: UInt8
    /// Offset from the region start, in beats.
    var startBeat: Double
    var duration: Double
}
