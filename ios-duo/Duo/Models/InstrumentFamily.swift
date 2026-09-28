import Foundation

/// The five instrument groups a track can belong to.
nonisolated enum InstrumentFamily: String, CaseIterable, Codable, Identifiable, Sendable {
    case guitar
    case bass
    case drums
    case keys
    case brass

    var id: String { rawValue }

    var title: String {
        switch self {
        case .guitar: "Guitar"
        case .bass: "Bass"
        case .drums: "Drums"
        case .keys: "Keys"
        case .brass: "Brass"
        }
    }

    /// Whether the emulation picker offers a Real / MIDI split.
    var hasMIDIVariants: Bool {
        switch self {
        case .drums, .keys: true
        default: false
        }
    }
}
