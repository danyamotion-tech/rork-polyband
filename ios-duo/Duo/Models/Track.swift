import Foundation

/// One instrument lane in a project.
nonisolated struct Track: Identifiable, Hashable, Codable, Sendable {
    var id: UUID = UUID()
    var family: InstrumentFamily
    var emulationID: String
    var isMuted: Bool = false
    var isSoloed: Bool = false
    var regions: [Region] = []
    /// 16-step patterns for MIDI drum pads, keyed by drum pitch.
    var drumPattern: [Int: [Bool]] = [:]

    var emulation: Emulation {
        EmulationCatalog.emulation(id: emulationID) ?? EmulationCatalog.defaultEmulation(for: family)
    }

    var contentEndBeat: Double {
        regions.map(\.endBeat).max() ?? 0
    }

    static func make(_ family: InstrumentFamily, emulationID: String? = nil) -> Track {
        Track(family: family, emulationID: emulationID ?? EmulationCatalog.defaultEmulation(for: family).id)
    }
}
