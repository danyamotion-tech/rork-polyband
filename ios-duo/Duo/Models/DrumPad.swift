import Foundation

/// A named percussion sound mapped to a General MIDI drum pitch.
nonisolated struct DrumPad: Identifiable, Hashable, Sendable {
    let name: String
    let pitch: UInt8
    var id: UInt8 { pitch }

    /// 4x4 pad grid for MIDI drum kits.
    static let grid: [DrumPad] = [
        DrumPad(name: "Kick", pitch: 36), DrumPad(name: "Snare", pitch: 38), DrumPad(name: "Clap", pitch: 39), DrumPad(name: "Rim", pitch: 37),
        DrumPad(name: "CH", pitch: 42), DrumPad(name: "OH", pitch: 46), DrumPad(name: "Cymbal", pitch: 49), DrumPad(name: "Cowbell", pitch: 56),
        DrumPad(name: "Tom Low", pitch: 45), DrumPad(name: "Tom Mid", pitch: 47), DrumPad(name: "Tom High", pitch: 50), DrumPad(name: "Shaker", pitch: 70),
        DrumPad(name: "Perc 1", pitch: 60), DrumPad(name: "Perc 2", pitch: 63), DrumPad(name: "Perc 3", pitch: 75), DrumPad(name: "FX", pitch: 55),
    ]
}
