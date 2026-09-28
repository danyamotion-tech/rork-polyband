import Foundation

/// A ready-made musical phrase that can be dropped into a project.
nonisolated struct LoopPreset: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let family: InstrumentFamily
    let emulationID: String
    let bars: Int
    let notes: [NoteEvent]

    var lengthBeats: Double { Double(bars * 4) }

    static let all: [LoopPreset] = [
        LoopPreset(id: "loop-808-basic", name: "808 Backbone", family: .drums, emulationID: "drm-808", bars: 2, notes: drumLoop(kick: [0, 2.5, 4, 6.5], snare: [1, 3, 5, 7], hat: stride(from: 0.0, to: 8, by: 0.5).map { $0 })),
        LoopPreset(id: "loop-vintage-groove", name: "Vintage Groove", family: .drums, emulationID: "drm-vintage", bars: 2, notes: drumLoop(kick: [0, 1.5, 4, 5.5, 6], snare: [1, 3, 5, 7], hat: stride(from: 0.0, to: 8, by: 1).map { $0 })),
        LoopPreset(id: "loop-pbass-walk", name: "P-Bass Walk", family: .bass, emulationID: "bass-p", bars: 2, notes: melody([40, 40, 47, 45, 43, 43, 45, 47], step: 1, duration: 0.9)),
        LoopPreset(id: "loop-rhodes-chords", name: "Rhodes Chords", family: .keys, emulationID: "key-rhodes", bars: 2, notes: chords([[57, 60, 64], [55, 59, 62], [53, 57, 60], [55, 59, 62]], step: 2, duration: 1.8)),
        LoopPreset(id: "loop-juno-pad", name: "Juno Drift", family: .keys, emulationID: "key-juno", bars: 4, notes: chords([[52, 59, 64, 67], [50, 57, 62, 66]], step: 8, duration: 7.5)),
        LoopPreset(id: "loop-funk-riff", name: "Funk Riff", family: .guitar, emulationID: "gtr-strat", bars: 1, notes: melody([64, 64, 67, 64, 62, 64, 60, 62], step: 0.5, duration: 0.3)),
        LoopPreset(id: "loop-brass-stab", name: "Brass Stabs", family: .brass, emulationID: "brs-section", bars: 2, notes: chords([[67, 71, 74], [], [65, 69, 72], [], [67, 71, 74], [], [62, 66, 69], []], step: 1, duration: 0.4)),
    ]

    private static func drumLoop(kick: [Double], snare: [Double], hat: [Double]) -> [NoteEvent] {
        var notes: [NoteEvent] = []
        notes += kick.map { NoteEvent(pitch: 36, velocity: 110, startBeat: $0, duration: 0.25) }
        notes += snare.map { NoteEvent(pitch: 38, velocity: 100, startBeat: $0, duration: 0.25) }
        notes += hat.map { NoteEvent(pitch: 42, velocity: 70, startBeat: $0, duration: 0.2) }
        return notes.sorted { $0.startBeat < $1.startBeat }
    }

    private static func melody(_ pitches: [UInt8], step: Double, duration: Double) -> [NoteEvent] {
        pitches.enumerated().map { index, pitch in
            NoteEvent(pitch: pitch, velocity: 96, startBeat: Double(index) * step, duration: duration)
        }
    }

    private static func chords(_ chords: [[UInt8]], step: Double, duration: Double) -> [NoteEvent] {
        var notes: [NoteEvent] = []
        for (index, chord) in chords.enumerated() {
            for pitch in chord {
                notes.append(NoteEvent(pitch: pitch, velocity: 90, startBeat: Double(index) * step, duration: duration))
            }
        }
        return notes
    }
}
