import Foundation
import Observation
import QuartzCore
import UIKit

/// Drives transport, playback scheduling, live performance and recording for one project.
@Observable
final class SequencerViewModel {
    var project: Project
    var selectedFamily: InstrumentFamily = .drums
    var isPlaying = false
    var isRecording = false
    var isMetronomeOn = false
    var isPickingEmulation = false
    /// Current playhead position in beats.
    var positionBeats: Double = 0

    private let engine: AudioEngine
    private let store: ProjectStore
    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval = 0
    private var lastScheduledBeat: Double = -1
    private var activeNotes: [(pitch: UInt8, family: InstrumentFamily, offBeat: Double)] = []
    private var liveNotes: [UInt8: Double] = [:]
    private var recordingRegionID: UUID?
    private var recordingStartBeat: Double = 0
    private let impact = UIImpactFeedbackGenerator(style: .light)

    init(project: Project, store: ProjectStore, engine: AudioEngine) {
        self.project = project
        self.store = store
        self.engine = engine
        engine.start()
        for track in project.tracks {
            engine.load(track.emulation)
        }
        applyMix()
    }

    // MARK: - Derived

    var selectedTrack: Track {
        project.track(for: selectedFamily) ?? Track.make(selectedFamily)
    }

    var selectedTrackIndex: Int? {
        project.tracks.firstIndex { $0.family == selectedFamily }
    }

    var secondsPerBeat: Double { 60 / project.bpm }

    /// "bar.beat.tick" transport readout.
    var positionLabel: String {
        let bar = Int(positionBeats / Double(project.beatsPerBar)) + 1
        let beat = Int(positionBeats.truncatingRemainder(dividingBy: Double(project.beatsPerBar))) + 1
        let tick = Int((positionBeats - positionBeats.rounded(.down)) * 4) + 1
        return "\(bar).\(beat).\(tick)"
    }

    var currentStep: Int {
        Int((positionBeats * 4).rounded(.down)) % 16
    }

    // MARK: - Transport

    func togglePlay() {
        if isPlaying { stop() } else { play() }
    }

    func play() {
        guard !isPlaying else { return }
        engine.start()
        isPlaying = true
        lastScheduledBeat = positionBeats - 0.001
        lastTimestamp = 0
        let link = CADisplayLink(target: self, selector: #selector(tick(_:)))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    func stop() {
        displayLink?.invalidate()
        displayLink = nil
        isPlaying = false
        finishRecording()
        for note in activeNotes {
            engine.noteOff(note.pitch, family: note.family)
        }
        activeNotes.removeAll()
    }

    func rewind() {
        let wasPlaying = isPlaying
        stop()
        positionBeats = 0
        if wasPlaying { play() }
    }

    func toggleRecord() {
        if isRecording {
            finishRecording()
        } else {
            beginRecording()
            if !isPlaying { play() }
        }
    }

    func setBPM(_ bpm: Double) {
        project.bpm = min(240, max(40, bpm))
        persist()
    }

    // MARK: - Tracks

    func select(_ family: InstrumentFamily) {
        guard family != selectedFamily else { return }
        if isRecording { finishRecording() }
        selectedFamily = family
    }

    func toggleMute(_ trackID: UUID) {
        guard let index = project.tracks.firstIndex(where: { $0.id == trackID }) else { return }
        project.tracks[index].isMuted.toggle()
        applyMix()
        persist()
    }

    func toggleSolo(_ trackID: UUID) {
        guard let index = project.tracks.firstIndex(where: { $0.id == trackID }) else { return }
        project.tracks[index].isSoloed.toggle()
        applyMix()
        persist()
    }

    func setEmulation(_ emulation: Emulation) {
        guard let index = project.tracks.firstIndex(where: { $0.family == emulation.family }) else { return }
        project.tracks[index].emulationID = emulation.id
        engine.load(emulation)
        persist()
    }

    /// Moves a region so that it starts at the given beat, snapped to whole beats.
    func moveRegion(trackID: UUID, regionID: UUID, toStartBeat beat: Double) {
        guard let trackIndex = project.tracks.firstIndex(where: { $0.id == trackID }),
              let regionIndex = project.tracks[trackIndex].regions.firstIndex(where: { $0.id == regionID }),
              project.tracks[trackIndex].regions[regionIndex].id != recordingRegionID else { return }
        let snapped = max(0, beat.rounded())
        guard project.tracks[trackIndex].regions[regionIndex].startBeat != snapped else { return }
        project.tracks[trackIndex].regions[regionIndex].startBeat = snapped
        impact.impactOccurred(intensity: 0.6)
        persist()
    }

    func liftFeedback() {
        impact.impactOccurred(intensity: 0.9)
    }

    func clearSelectedTrack() {
        guard let index = selectedTrackIndex else { return }
        project.tracks[index].regions.removeAll()
        project.tracks[index].drumPattern.removeAll()
        persist()
    }

    func addLoop(_ loop: LoopPreset) {
        guard let index = project.tracks.firstIndex(where: { $0.family == loop.family }) else { return }
        var track = project.tracks[index]
        track.emulationID = loop.emulationID
        let start = track.contentEndBeat.rounded(.up)
        let notes = loop.notes.map { note in
            var copy = note
            copy.id = UUID()
            return copy
        }
        track.regions.append(Region(startBeat: start, lengthBeats: loop.lengthBeats, notes: notes))
        project.tracks[index] = track
        engine.load(track.emulation)
        selectedFamily = loop.family
        persist()
    }

    // MARK: - Step sequencer

    func isStepActive(pitch: UInt8, step: Int) -> Bool {
        selectedTrack.drumPattern[Int(pitch)]?[step] ?? false
    }

    func toggleStep(pitch: UInt8, step: Int) {
        guard let index = selectedTrackIndex else { return }
        var row = project.tracks[index].drumPattern[Int(pitch)] ?? Array(repeating: false, count: 16)
        row[step].toggle()
        project.tracks[index].drumPattern[Int(pitch)] = row
        impact.impactOccurred(intensity: 0.5)
        persist()
    }

    // MARK: - Live performance

    /// Previews a sound without writing anything into the recording region
    /// (used when choosing a pad for the step pattern).
    func audition(_ pitch: UInt8, velocity: UInt8 = 100) {
        engine.load(selectedTrack.emulation)
        engine.noteOn(pitch, velocity: velocity, family: selectedFamily)
        activeNotes.append((pitch, selectedFamily, positionBeats + 0.25))
        impact.impactOccurred(intensity: 0.5)
        if !isPlaying {
            let family = selectedFamily
            Task { @MainActor [engine] in
                try? await Task.sleep(for: .milliseconds(250))
                engine.noteOff(pitch, family: family)
            }
        }
    }

    func noteOn(_ pitch: UInt8, velocity: UInt8 = 100) {
        let family = selectedFamily
        engine.load(selectedTrack.emulation)
        engine.noteOn(pitch, velocity: velocity, family: family)
        impact.impactOccurred(intensity: 0.7)
        if isRecording {
            liveNotes[pitch] = positionBeats
            if selectedTrack.emulation.isPercussion {
                commitNote(pitch: pitch, velocity: velocity, start: positionBeats, duration: 0.25)
                liveNotes[pitch] = nil
            }
        }
    }

    func noteOff(_ pitch: UInt8) {
        engine.noteOff(pitch, family: selectedFamily)
        if let start = liveNotes.removeValue(forKey: pitch) {
            let duration = max(0.125, positionBeats - start)
            commitNote(pitch: pitch, velocity: 100, start: start, duration: duration)
        }
    }

    // MARK: - Recording

    private func beginRecording() {
        guard let index = selectedTrackIndex else { return }
        isRecording = true
        recordingStartBeat = (positionBeats / Double(project.beatsPerBar)).rounded(.down) * Double(project.beatsPerBar)
        let region = Region(startBeat: recordingStartBeat, lengthBeats: max(1, positionBeats - recordingStartBeat + 1), notes: [])
        recordingRegionID = region.id
        project.tracks[index].regions.append(region)
    }

    private func finishRecording() {
        guard isRecording else { return }
        isRecording = false
        for (pitch, start) in liveNotes {
            engine.noteOff(pitch, family: selectedFamily)
            commitNote(pitch: pitch, velocity: 100, start: start, duration: max(0.125, positionBeats - start))
        }
        liveNotes.removeAll()
        if let index = selectedTrackIndex,
           let regionIndex = project.tracks[index].regions.firstIndex(where: { $0.id == recordingRegionID }) {
            var region = project.tracks[index].regions[regionIndex]
            if region.notes.isEmpty {
                project.tracks[index].regions.remove(at: regionIndex)
            } else {
                let bars = ((region.lengthBeats) / Double(project.beatsPerBar)).rounded(.up)
                region.lengthBeats = max(Double(project.beatsPerBar), bars * Double(project.beatsPerBar))
                project.tracks[index].regions[regionIndex] = region
            }
        }
        recordingRegionID = nil
        persist()
    }

    private func commitNote(pitch: UInt8, velocity: UInt8, start: Double, duration: Double) {
        guard let index = selectedTrackIndex,
              let regionIndex = project.tracks[index].regions.firstIndex(where: { $0.id == recordingRegionID }) else { return }
        var region = project.tracks[index].regions[regionIndex]
        let offset = start - region.startBeat
        guard offset >= 0 else { return }
        region.notes.append(NoteEvent(pitch: pitch, velocity: velocity, startBeat: offset, duration: duration))
        region.lengthBeats = max(region.lengthBeats, offset + duration)
        project.tracks[index].regions[regionIndex] = region
    }

    // MARK: - Scheduling

    @objc private func tick(_ link: CADisplayLink) {
        if lastTimestamp == 0 {
            lastTimestamp = link.timestamp
            return
        }
        let delta = link.timestamp - lastTimestamp
        lastTimestamp = link.timestamp
        let previous = positionBeats
        var next = previous + delta / secondsPerBeat
        let loop = project.loopBeats
        if next >= loop {
            if isRecording { finishRecording() }
            next -= loop
            lastScheduledBeat = -0.001
            schedule(from: previous, to: loop)
        }
        schedule(from: max(lastScheduledBeat, next - delta / secondsPerBeat), to: next)
        lastScheduledBeat = next
        positionBeats = next
        if isRecording, let index = selectedTrackIndex,
           let regionIndex = project.tracks[index].regions.firstIndex(where: { $0.id == recordingRegionID }) {
            project.tracks[index].regions[regionIndex].lengthBeats = max(project.tracks[index].regions[regionIndex].lengthBeats, next - recordingStartBeat)
        }
        releaseFinishedNotes(at: next)
    }

    private func schedule(from start: Double, to end: Double) {
        guard end > start else { return }
        let soloActive = project.tracks.contains { $0.isSoloed }
        for track in project.tracks {
            if track.isMuted || (soloActive && !track.isSoloed) { continue }
            for region in track.regions where region.id != recordingRegionID {
                for note in region.notes {
                    let absolute = region.startBeat + note.startBeat
                    if absolute >= start && absolute < end {
                        engine.noteOn(note.pitch, velocity: note.velocity, family: track.family)
                        activeNotes.append((note.pitch, track.family, absolute + note.duration))
                    }
                }
            }
            if track.family == selectedFamily, track.emulation.kind == .midi, track.emulation.isPercussion {
                scheduleSteps(track, from: start, to: end)
            }
        }
        if isMetronomeOn {
            let firstBeat = start.rounded(.up)
            if firstBeat < end {
                let isDownbeat = Int(firstBeat) % project.beatsPerBar == 0
                engine.noteOn(isDownbeat ? 76 : 77, velocity: isDownbeat ? 90 : 60, family: .drums)
                activeNotes.append((isDownbeat ? 76 : 77, .drums, firstBeat + 0.1))
            }
        }
    }

    private func scheduleSteps(_ track: Track, from start: Double, to end: Double) {
        let firstStep = Int((start * 4).rounded(.up))
        let lastStep = Int((end * 4).rounded(.up))
        guard lastStep > firstStep else { return }
        let loop = project.loopBeats
        for step in firstStep..<lastStep {
            let index = step % 16
            let beat = Double(step) / 4
            let noteBeat = beat >= loop ? beat - loop : beat
            for (pitch, row) in track.drumPattern where row.indices.contains(index) && row[index] {
                // A hit already printed into a finished region is played by that region — don't double it.
                if isPrinted(pitch: UInt8(pitch), at: noteBeat, in: track) { continue }
                engine.noteOn(UInt8(pitch), velocity: 100, family: track.family)
                activeNotes.append((UInt8(pitch), track.family, beat + 0.2))
                if isRecording {
                    commitNote(pitch: UInt8(pitch), velocity: 100, start: noteBeat, duration: 0.25)
                }
            }
        }
    }

    private func isPrinted(pitch: UInt8, at beat: Double, in track: Track) -> Bool {
        track.regions.contains { region in
            region.id != recordingRegionID && region.notes.contains { note in
                note.pitch == pitch && abs(region.startBeat + note.startBeat - beat) < 0.01
            }
        }
    }

    private func releaseFinishedNotes(at beat: Double) {
        let loop = project.loopBeats
        var remaining: [(pitch: UInt8, family: InstrumentFamily, offBeat: Double)] = []
        for note in activeNotes {
            let off = note.offBeat >= loop ? note.offBeat - loop : note.offBeat
            if off <= beat && beat - off < 2 {
                engine.noteOff(note.pitch, family: note.family)
            } else {
                remaining.append(note)
            }
        }
        activeNotes = remaining
    }

    private func applyMix() {
        let soloActive = project.tracks.contains { $0.isSoloed }
        for track in project.tracks {
            let audible = !track.isMuted && (!soloActive || track.isSoloed)
            engine.setVolume(audible ? 0.9 : 0, family: track.family)
        }
    }

    func persist() {
        store.update(project)
    }
}
