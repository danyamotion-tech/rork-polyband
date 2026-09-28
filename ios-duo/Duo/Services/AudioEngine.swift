import AVFoundation
import Foundation
import Observation

/// Plays notes for every instrument family using the system General MIDI bank.
@Observable
final class AudioEngine {
    @ObservationIgnored
    private let engine = AVAudioEngine()
    private var samplers: [InstrumentFamily: AVAudioUnitSampler] = [:]
    private var loadedPrograms: [InstrumentFamily: String] = [:]
    private var isStarted = false

    private static let bankURL: URL? = {
        let path = "/System/Library/Components/CoreAudio.component/Contents/Resources/gs_instruments.dls"
        return FileManager.default.fileExists(atPath: path) ? URL(fileURLWithPath: path) : nil
    }()

    init() {
        for family in InstrumentFamily.allCases {
            let sampler = AVAudioUnitSampler()
            engine.attach(sampler)
            engine.connect(sampler, to: engine.mainMixerNode, format: nil)
            samplers[family] = sampler
        }
    }

    /// Configures the audio session and starts the engine if needed.
    func start() {
        guard !isStarted else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
            try engine.start()
            isStarted = true
        } catch {
            print("[AudioEngine] failed to start: \(error.localizedDescription)")
        }
    }

    /// Loads the emulation's GM program into the family's sampler.
    func load(_ emulation: Emulation) {
        guard let sampler = samplers[emulation.family] else { return }
        if loadedPrograms[emulation.family] == emulation.id { return }
        loadedPrograms[emulation.family] = emulation.id
        guard let bank = Self.bankURL else { return }
        let msb = emulation.isPercussion ? UInt8(kAUSampler_DefaultPercussionBankMSB) : UInt8(kAUSampler_DefaultMelodicBankMSB)
        do {
            try sampler.loadSoundBankInstrument(at: bank, program: emulation.program, bankMSB: msb, bankLSB: UInt8(kAUSampler_DefaultBankLSB))
        } catch {
            print("[AudioEngine] failed to load \(emulation.name): \(error.localizedDescription)")
        }
    }

    func noteOn(_ pitch: UInt8, velocity: UInt8, family: InstrumentFamily) {
        start()
        samplers[family]?.startNote(pitch, withVelocity: velocity, onChannel: 0)
    }

    func noteOff(_ pitch: UInt8, family: InstrumentFamily) {
        samplers[family]?.stopNote(pitch, onChannel: 0)
    }

    func setVolume(_ volume: Float, family: InstrumentFamily) {
        samplers[family]?.volume = volume
    }

    func allNotesOff() {
        for (_, sampler) in samplers {
            for pitch in 0...127 {
                sampler.stopNote(UInt8(pitch), onChannel: 0)
            }
        }
    }
}
