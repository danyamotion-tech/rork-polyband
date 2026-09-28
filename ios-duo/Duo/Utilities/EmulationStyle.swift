import SwiftUI

/// Visual identity of an emulation, derived from the original hardware it references.
struct EmulationStyle {
    /// Guitar/bass body finish and hardware.
    enum Pickup { case humbucker, singleCoil, soundhole, fHole, split, none }
    enum Inlay { case dot, trapezoid, block, none }

    /// Keyboard control-panel treatment.
    enum KeyPanel { case grand, rhodes, wurlitzer, organ, clavinet, juno, moog, dx }

    /// Drum machine chassis.
    enum DrumMachine { case tr808, tr909, electro }

    /// Brass control layout.
    enum BrassControl { case valves, slide, rotary, saxKeys, section }

    /// Main body / chassis finish.
    let body: Color
    /// Secondary finish (panel, binding, second sunburst colour).
    let panel: Color
    /// Metal hardware (rails, frets, valves).
    let hardware: Color
    /// Signature colour of the original (808 red, 909 orange, Juno blue…).
    let signature: Color
    /// Engraved nameplate text.
    let plate: String

    var pickup: Pickup = .none
    var inlay: Inlay = .dot
    var hasFretWire: Bool = true
    var stringColor: Color = Color(hex: 0xC9C7C0)

    var keyPanel: KeyPanel = .grand
    var whiteKey: Color = Color(hex: 0xEDE9E1)
    var blackKey: Color = Color(hex: 0x1A1A1C)

    var drumMachine: DrumMachine = .tr808
    var brassControl: BrassControl = .valves

    /// Resolves the look for an emulation id, with a neutral matte fallback.
    static func style(for emulation: Emulation) -> EmulationStyle {
        switch emulation.id {
        // Guitar
        case "gtr-lespaul":
            return EmulationStyle(body: Color(hex: 0x5A1A10), panel: Color(hex: 0xC98A2E), hardware: Color(hex: 0xD3B06A), signature: Color(hex: 0xEBD9B0), plate: "Les Paul Standard", pickup: .humbucker, inlay: .trapezoid)
        case "gtr-strat":
            return EmulationStyle(body: Color(hex: 0x8FB8C8), panel: Color(hex: 0xF1EBDD), hardware: Color(hex: 0xC8CBCF), signature: Color(hex: 0xF1EBDD), plate: "Stratocaster", pickup: .singleCoil, inlay: .dot)
        case "gtr-es335":
            return EmulationStyle(body: Color(hex: 0x8E1C1C), panel: Color(hex: 0xEBD9B0), hardware: Color(hex: 0xD3B06A), signature: Color(hex: 0xEBD9B0), plate: "ES-335", pickup: .fHole, inlay: .dot)
        case "gtr-d28":
            return EmulationStyle(body: Color(hex: 0xD9B579), panel: Color(hex: 0x4A2C18), hardware: Color(hex: 0xC8CBCF), signature: Color(hex: 0xF2E7CE), plate: "D-28 Dreadnought", pickup: .soundhole, inlay: .dot)
        case "gtr-nylon":
            return EmulationStyle(body: Color(hex: 0xB8783A), panel: Color(hex: 0x3B2416), hardware: Color(hex: 0xD3B06A), signature: Color(hex: 0xF5E9D0), plate: "Classical Nylon", pickup: .soundhole, inlay: .none, stringColor: Color(hex: 0xF0E8D2))
        // Bass
        case "bass-p":
            return EmulationStyle(body: Color(hex: 0x2A1A10), panel: Color(hex: 0xB8752E), hardware: Color(hex: 0xC8CBCF), signature: Color(hex: 0x1B1B1B), plate: "Precision Bass", pickup: .split, inlay: .dot)
        case "bass-jazz":
            return EmulationStyle(body: Color(hex: 0x2F5D8C), panel: Color(hex: 0xEFE6D2), hardware: Color(hex: 0xC8CBCF), signature: Color(hex: 0xEFE6D2), plate: "Jazz Bass", pickup: .singleCoil, inlay: .block)
        case "bass-upright":
            return EmulationStyle(body: Color(hex: 0x5A2A14), panel: Color(hex: 0x2B160C), hardware: Color(hex: 0x1F1A17), signature: Color(hex: 0xE8D7B5), plate: "Upright Bass", pickup: .fHole, inlay: .none, hasFretWire: false, stringColor: Color(hex: 0xA8A49A))
        case "bass-fretless":
            return EmulationStyle(body: Color(hex: 0xC79A5B), panel: Color(hex: 0x3E2A18), hardware: Color(hex: 0xC8CBCF), signature: Color(hex: 0x1B1B1B), plate: "Fretless", pickup: .singleCoil, inlay: .none, hasFretWire: false)
        case "bass-slap":
            return EmulationStyle(body: Color(hex: 0xA0261F), panel: Color(hex: 0x141414), hardware: Color(hex: 0xD3B06A), signature: Color(hex: 0x141414), plate: "Active Slap", pickup: .humbucker, inlay: .dot)
        // Drums — real
        case "drm-vintage":
            return EmulationStyle(body: Color(hex: 0xB4722E), panel: Color(hex: 0x4A2C18), hardware: Color(hex: 0xC8CBCF), signature: Color(hex: 0xB4722E), plate: "Vintage Kit · 1968")
        case "drm-room":
            return EmulationStyle(body: Color(hex: 0xD4A86A), panel: Color(hex: 0x6B4A2C), hardware: Color(hex: 0xC8CBCF), signature: Color(hex: 0xD4A86A), plate: "Room Kit · Maple")
        case "drm-power":
            return EmulationStyle(body: Color(hex: 0x111214), panel: Color(hex: 0x2A2C30), hardware: Color(hex: 0xC8CBCF), signature: Color(hex: 0xC8CBCF), plate: "Power Kit · Black Chrome")
        case "drm-jazz":
            return EmulationStyle(body: Color(hex: 0x3F2A1C), panel: Color(hex: 0x6B4A2C), hardware: Color(hex: 0xD3B06A), signature: Color(hex: 0xD3B06A), plate: "Jazz Kit · Walnut")
        case "drm-brush":
            return EmulationStyle(body: Color(hex: 0xE6DCC6), panel: Color(hex: 0x8A7A62), hardware: Color(hex: 0xC8CBCF), signature: Color(hex: 0xE6DCC6), plate: "Brush Kit · Pearl")
        // Drums — MIDI
        case "drm-808":
            return EmulationStyle(body: Color(hex: 0x1B1B1B), panel: Color(hex: 0x2B2B2B), hardware: Color(hex: 0xD8D4CA), signature: Color(hex: 0xC8342A), plate: "Rhythm Composer TR-808", drumMachine: .tr808)
        case "drm-909":
            return EmulationStyle(body: Color(hex: 0x8F9190), panel: Color(hex: 0x2A2B2C), hardware: Color(hex: 0xE4E4E0), signature: Color(hex: 0xE0662A), plate: "Rhythm Composer TR-909", drumMachine: .tr909)
        case "drm-electro":
            return EmulationStyle(body: Color(hex: 0x0E1114), panel: Color(hex: 0x1A1F24), hardware: Color(hex: 0x9AA3AB), signature: Color(hex: 0x4FC1C9), plate: "Electro Kit", drumMachine: .electro)
        // Keys — real
        case "key-grand":
            return EmulationStyle(body: Color(hex: 0x0B0B0C), panel: Color(hex: 0x1A1A1C), hardware: Color(hex: 0xD3B06A), signature: Color(hex: 0xD3B06A), plate: "Model D Concert Grand", keyPanel: .grand, whiteKey: Color(hex: 0xF4F1EA), blackKey: Color(hex: 0x141416))
        case "key-rhodes":
            return EmulationStyle(body: Color(hex: 0x1C1C1E), panel: Color(hex: 0xB9BCC0), hardware: Color(hex: 0xC8CBCF), signature: Color(hex: 0xC8CBCF), plate: "Rhodes Mark I · 73", keyPanel: .rhodes, whiteKey: Color(hex: 0xEDE6D3), blackKey: Color(hex: 0x1B1B1B))
        case "key-wurli":
            return EmulationStyle(body: Color(hex: 0x151515), panel: Color(hex: 0xE3D9BE), hardware: Color(hex: 0xC8CBCF), signature: Color(hex: 0xE3D9BE), plate: "Wurlitzer 200A", keyPanel: .wurlitzer, whiteKey: Color(hex: 0xEFE9DA), blackKey: Color(hex: 0x1E1E1E))
        case "key-b3":
            return EmulationStyle(body: Color(hex: 0x4A2E1A), panel: Color(hex: 0x2C1A0F), hardware: Color(hex: 0xD3B06A), signature: Color(hex: 0xE6E1D3), plate: "Hammond B-3", keyPanel: .organ, whiteKey: Color(hex: 0xF1EDE2), blackKey: Color(hex: 0x1A1A1A))
        case "key-clav":
            return EmulationStyle(body: Color(hex: 0x3B2416), panel: Color(hex: 0x1B1B1B), hardware: Color(hex: 0xC8CBCF), signature: Color(hex: 0xD6A85F), plate: "Clavinet D6", keyPanel: .clavinet, whiteKey: Color(hex: 0xEDE7D8), blackKey: Color(hex: 0x1C1C1C))
        // Keys — MIDI
        case "key-juno":
            return EmulationStyle(body: Color(hex: 0x2B2D30), panel: Color(hex: 0x1C1D20), hardware: Color(hex: 0xC8CBCF), signature: Color(hex: 0x4A7BD1), plate: "JUNO-60", keyPanel: .juno, whiteKey: Color(hex: 0xE9E7E1), blackKey: Color(hex: 0x1A1A1A))
        case "key-moog":
            return EmulationStyle(body: Color(hex: 0x5C3A1E), panel: Color(hex: 0x141414), hardware: Color(hex: 0xC8CBCF), signature: Color(hex: 0xE0662A), plate: "Minimoog Model D", keyPanel: .moog, whiteKey: Color(hex: 0xEDE9E1), blackKey: Color(hex: 0x1A1A1A))
        case "key-fmbell":
            return EmulationStyle(body: Color(hex: 0x2E2A26), panel: Color(hex: 0x1C1A18), hardware: Color(hex: 0xC8CBCF), signature: Color(hex: 0x3FBF9B), plate: "DX7 Digital Programmable", keyPanel: .dx, whiteKey: Color(hex: 0xE9E7E1), blackKey: Color(hex: 0x1A1A1A))
        // Brass
        case "brs-trumpet":
            return EmulationStyle(body: Color(hex: 0xC9962E), panel: Color(hex: 0x6A4A12), hardware: Color(hex: 0xEFE3C4), signature: Color(hex: 0xEFE3C4), plate: "Bb Trumpet", brassControl: .valves)
        case "brs-trombone":
            return EmulationStyle(body: Color(hex: 0xC48D3A), panel: Color(hex: 0x5A3E14), hardware: Color(hex: 0xC8CBCF), signature: Color(hex: 0xEFE3C4), plate: "Tenor Trombone", brassControl: .slide)
        case "brs-horn":
            return EmulationStyle(body: Color(hex: 0xB7862F), panel: Color(hex: 0x4A3410), hardware: Color(hex: 0xC8CBCF), signature: Color(hex: 0xEFE3C4), plate: "Double Horn in F/Bb", brassControl: .rotary)
        case "brs-sax":
            return EmulationStyle(body: Color(hex: 0xD3A43E), panel: Color(hex: 0x5E4312), hardware: Color(hex: 0xF1EBDD), signature: Color(hex: 0xF1EBDD), plate: "Tenor Saxophone", brassControl: .saxKeys)
        case "brs-section":
            return EmulationStyle(body: Color(hex: 0xC9962E), panel: Color(hex: 0x6A4A12), hardware: Color(hex: 0xEFE3C4), signature: Color(hex: 0xEFE3C4), plate: "Brass Section", brassControl: .section)
        default:
            return EmulationStyle(body: DuoTheme.surface, panel: DuoTheme.surfaceSecondary, hardware: DuoTheme.textSecondary, signature: DuoTheme.accent, plate: emulation.name)
        }
    }
}

/// Small engraved plate with the instrument model name.
struct NamePlate: View {
    let text: String
    let foreground: Color
    var background: Color = .black.opacity(0.35)

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 9, weight: .semibold, design: .rounded))
            .tracking(1.4)
            .foregroundStyle(foreground)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(background, in: .rect(cornerRadius: 3))
            .overlay(RoundedRectangle(cornerRadius: 3).stroke(foreground.opacity(0.35), lineWidth: 0.5))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
    }
}
