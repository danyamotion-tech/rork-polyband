import Foundation

/// A specific instrument emulation (e.g. Rhodes Mark I) mapped to a General MIDI program.
nonisolated struct Emulation: Identifiable, Hashable, Codable, Sendable {
    nonisolated enum Kind: String, Codable, Sendable {
        case real
        case midi

        var title: String {
            switch self {
            case .real: "Real"
            case .midi: "MIDI"
            }
        }
    }

    let id: String
    let name: String
    let subtitle: String
    let kind: Kind
    let family: InstrumentFamily
    /// General MIDI program number (0-127).
    let program: UInt8
    /// Uses the percussion bank; pitches map to drum sounds.
    let isPercussion: Bool
}

/// Static catalog of every emulation grouped by family.
nonisolated enum EmulationCatalog {
    static let all: [Emulation] = [
        // Guitar
        Emulation(id: "gtr-lespaul", name: "Les Paul", subtitle: "overdriven humbuckers", kind: .real, family: .guitar, program: 29, isPercussion: false),
        Emulation(id: "gtr-strat", name: "Stratocaster", subtitle: "clean single coils", kind: .real, family: .guitar, program: 27, isPercussion: false),
        Emulation(id: "gtr-es335", name: "ES-335", subtitle: "warm jazz hollowbody", kind: .real, family: .guitar, program: 26, isPercussion: false),
        Emulation(id: "gtr-d28", name: "Martin D-28", subtitle: "steel-string acoustic", kind: .real, family: .guitar, program: 25, isPercussion: false),
        Emulation(id: "gtr-nylon", name: "Classical Nylon", subtitle: "soft fingerstyle", kind: .real, family: .guitar, program: 24, isPercussion: false),
        // Bass
        Emulation(id: "bass-p", name: "P-Bass", subtitle: "fingered, round and deep", kind: .real, family: .bass, program: 33, isPercussion: false),
        Emulation(id: "bass-jazz", name: "Jazz Bass", subtitle: "picked, bright", kind: .real, family: .bass, program: 34, isPercussion: false),
        Emulation(id: "bass-upright", name: "Upright", subtitle: "acoustic double bass", kind: .real, family: .bass, program: 32, isPercussion: false),
        Emulation(id: "bass-fretless", name: "Fretless", subtitle: "singing mwah", kind: .real, family: .bass, program: 35, isPercussion: false),
        Emulation(id: "bass-slap", name: "Slap Bass", subtitle: "funky thumb", kind: .real, family: .bass, program: 36, isPercussion: false),
        // Drums — real
        Emulation(id: "drm-vintage", name: "Vintage Kit", subtitle: "warm studio kit", kind: .real, family: .drums, program: 0, isPercussion: true),
        Emulation(id: "drm-room", name: "Room Kit", subtitle: "live room ambience", kind: .real, family: .drums, program: 8, isPercussion: true),
        Emulation(id: "drm-power", name: "Power Kit", subtitle: "big rock drums", kind: .real, family: .drums, program: 16, isPercussion: true),
        Emulation(id: "drm-jazz", name: "Jazz Kit", subtitle: "tight and dry", kind: .real, family: .drums, program: 32, isPercussion: true),
        Emulation(id: "drm-brush", name: "Brush Kit", subtitle: "soft brushes", kind: .real, family: .drums, program: 40, isPercussion: true),
        // Drums — MIDI
        Emulation(id: "drm-808", name: "TR-808", subtitle: "analog drum machine", kind: .midi, family: .drums, program: 25, isPercussion: true),
        Emulation(id: "drm-909", name: "TR-909", subtitle: "punchy electronic", kind: .midi, family: .drums, program: 24, isPercussion: true),
        Emulation(id: "drm-electro", name: "Electro Kit", subtitle: "synthetic hits", kind: .midi, family: .drums, program: 24, isPercussion: true),
        // Keys — real
        Emulation(id: "key-grand", name: "Grand Piano", subtitle: "Steinway D concert grand", kind: .real, family: .keys, program: 0, isPercussion: false),
        Emulation(id: "key-rhodes", name: "Rhodes Mark I", subtitle: "warm electric piano", kind: .real, family: .keys, program: 4, isPercussion: false),
        Emulation(id: "key-wurli", name: "Wurlitzer 200A", subtitle: "tube, slightly gritty", kind: .real, family: .keys, program: 5, isPercussion: false),
        Emulation(id: "key-b3", name: "Hammond B3", subtitle: "organ with Leslie", kind: .real, family: .keys, program: 16, isPercussion: false),
        Emulation(id: "key-clav", name: "Clavinet D6", subtitle: "funky pluck", kind: .real, family: .keys, program: 7, isPercussion: false),
        // Keys — MIDI
        Emulation(id: "key-juno", name: "Juno-60 Pad", subtitle: "analog pad", kind: .midi, family: .keys, program: 89, isPercussion: false),
        Emulation(id: "key-moog", name: "Minimoog Lead", subtitle: "fat lead", kind: .midi, family: .keys, program: 81, isPercussion: false),
        Emulation(id: "key-fmbell", name: "FM Bell", subtitle: "glassy bell", kind: .midi, family: .keys, program: 98, isPercussion: false),
        // Brass
        Emulation(id: "brs-trumpet", name: "Trumpet", subtitle: "bright Bb trumpet", kind: .real, family: .brass, program: 56, isPercussion: false),
        Emulation(id: "brs-trombone", name: "Trombone", subtitle: "smooth slide", kind: .real, family: .brass, program: 57, isPercussion: false),
        Emulation(id: "brs-horn", name: "French Horn", subtitle: "round and noble", kind: .real, family: .brass, program: 60, isPercussion: false),
        Emulation(id: "brs-sax", name: "Tenor Sax", subtitle: "breathy reed", kind: .real, family: .brass, program: 66, isPercussion: false),
        Emulation(id: "brs-section", name: "Brass Section", subtitle: "full ensemble", kind: .real, family: .brass, program: 61, isPercussion: false),
    ]

    static func emulations(for family: InstrumentFamily) -> [Emulation] {
        all.filter { $0.family == family }
    }

    static func emulation(id: String) -> Emulation? {
        all.first { $0.id == id }
    }

    static func defaultEmulation(for family: InstrumentFamily) -> Emulation {
        emulations(for: family).first ?? all[0]
    }
}
