import Foundation

/// A song: tempo plus a set of tracks.
nonisolated struct Project: Identifiable, Hashable, Codable, Sendable {
    var id: UUID = UUID()
    var name: String
    var bpm: Double
    var beatsPerBar: Int = 4
    var tracks: [Track]
    var lastEdited: Date

    /// Total loop length in beats (at least 16 bars).
    var loopBeats: Double {
        let content = tracks.map(\.contentEndBeat).max() ?? 0
        let bars = max(16, Int((content / Double(beatsPerBar)).rounded(.up)))
        return Double(bars * beatsPerBar)
    }

    var populatedTrackCount: Int {
        tracks.filter { !$0.regions.isEmpty }.count
    }

    func track(for family: InstrumentFamily) -> Track? {
        tracks.first { $0.family == family }
    }
}
