import Foundation

/// A block of notes on the timeline.
nonisolated struct Region: Identifiable, Hashable, Codable, Sendable {
    var id: UUID = UUID()
    var startBeat: Double
    var lengthBeats: Double
    var notes: [NoteEvent]

    var endBeat: Double { startBeat + lengthBeats }
}
