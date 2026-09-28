import Foundation

/// Seed projects shown on first launch.
nonisolated enum SampleData {
    static var projects: [Project] {
        return [
            makeProject(name: "Night Drive", bpm: 112, daysAgo: 1, tracks: [
                trackFrom(loop: "loop-vintage-groove", repeats: 4),
                trackFrom(loop: "loop-pbass-walk", repeats: 4),
                trackFrom(loop: "loop-rhodes-chords", repeats: 4),
                trackFrom(loop: "loop-brass-stab", repeats: 2, startBar: 4),
                Track.make(.guitar, emulationID: "gtr-lespaul"),
            ]),
            makeProject(name: "Lo-fi Sketch", bpm: 86, daysAgo: 7, tracks: [
                trackFrom(loop: "loop-808-basic", repeats: 4),
                trackFrom(loop: "loop-juno-pad", repeats: 2),
                trackFrom(loop: "loop-pbass-walk", repeats: 2, startBar: 4),
                Track.make(.guitar), Track.make(.brass),
            ]),
            makeProject(name: "Funk Riff", bpm: 104, daysAgo: 14, tracks: [
                trackFrom(loop: "loop-vintage-groove", repeats: 4),
                trackFrom(loop: "loop-funk-riff", repeats: 8),
                trackFrom(loop: "loop-pbass-walk", repeats: 4),
                trackFrom(loop: "loop-rhodes-chords", repeats: 2, startBar: 4),
                trackFrom(loop: "loop-brass-stab", repeats: 4),
            ]),
            makeProject(name: "Demo for Anna", bpm: 128, daysAgo: 19, tracks: [
                trackFrom(loop: "loop-808-basic", repeats: 4),
                trackFrom(loop: "loop-juno-pad", repeats: 2),
                Track.make(.guitar), Track.make(.bass), Track.make(.brass),
            ]),
            makeProject(name: "Sunset Jam", bpm: 90, daysAgo: 25, tracks: [
                trackFrom(loop: "loop-vintage-groove", repeats: 2),
                trackFrom(loop: "loop-rhodes-chords", repeats: 2),
                trackFrom(loop: "loop-funk-riff", repeats: 4),
                Track.make(.bass), Track.make(.brass),
            ]),
            makeProject(name: "Ideas", bpm: 100, daysAgo: 31, tracks: [
                trackFrom(loop: "loop-808-basic", repeats: 2),
                Track.make(.guitar), Track.make(.bass), Track.make(.keys), Track.make(.brass),
            ]),
        ]
    }

    private static func makeProject(name: String, bpm: Double, daysAgo: Double, tracks: [Track]) -> Project {
        let ordered = InstrumentFamily.allCases.compactMap { family in tracks.first { $0.family == family } }
        return Project(name: name, bpm: bpm, tracks: ordered, lastEdited: Date().addingTimeInterval(-86_400 * daysAgo))
    }

    private static func trackFrom(loop id: String, repeats: Int, startBar: Int = 0) -> Track {
        guard let loop = LoopPreset.all.first(where: { $0.id == id }) else {
            return Track.make(.guitar)
        }
        var track = Track.make(loop.family, emulationID: loop.emulationID)
        let start = Double(startBar * 4)
        let notes = (0..<repeats).flatMap { repetition in
            loop.notes.map { note in
                var copy = note
                copy.id = UUID()
                copy.startBeat += Double(repetition) * loop.lengthBeats
                return copy
            }
        }
        track.regions = [Region(startBeat: start, lengthBeats: loop.lengthBeats * Double(repeats), notes: notes)]
        if loop.family == .drums {
            track.drumPattern = patternFrom(loop.notes)
        }
        return track
    }

    private static func patternFrom(_ notes: [NoteEvent]) -> [Int: [Bool]] {
        var pattern: [Int: [Bool]] = [:]
        for note in notes where note.startBeat < 4 {
            let step = Int((note.startBeat * 4).rounded())
            guard (0..<16).contains(step) else { continue }
            var row = pattern[Int(note.pitch)] ?? Array(repeating: false, count: 16)
            row[step] = true
            pattern[Int(note.pitch)] = row
        }
        return pattern
    }
}
