import SwiftUI

/// Browse every emulation by family and audition it.
struct InstrumentsView: View {
    @Environment(AudioEngine.self) private var engine
    @State private var family: InstrumentFamily = .keys

    var body: some View {
        NavigationStack {
            ZStack {
                DuoTheme.canvas.ignoresSafeArea()
                List {
                    Section {
                        Picker("Instrument", selection: $family) {
                            ForEach(InstrumentFamily.allCases) { item in
                                Text(item.title).tag(item)
                            }
                        }
                        .pickerStyle(.segmented)
                        .listRowBackground(DuoTheme.canvas)
                        .listRowSeparator(.hidden)
                    }
                    ForEach(sections, id: \.kind) { section in
                        Section(section.kind == .real ? "Real" : "MIDI Synths") {
                            ForEach(section.items) { emulation in
                                Button {
                                    audition(emulation)
                                } label: {
                                    EmulationRow(emulation: emulation, isSelected: false)
                                }
                                .buttonStyle(.plain)
                                .listRowBackground(DuoTheme.canvas)
                                .listRowSeparatorTint(DuoTheme.hairline)
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Instruments")
        }
    }

    private var sections: [(kind: Emulation.Kind, items: [Emulation])] {
        let items = EmulationCatalog.emulations(for: family)
        let real = items.filter { $0.kind == .real }
        let midi = items.filter { $0.kind == .midi }
        var result: [(Emulation.Kind, [Emulation])] = [(.real, real)]
        if !midi.isEmpty { result.append((.midi, midi)) }
        return result
    }

    private func audition(_ emulation: Emulation) {
        engine.load(emulation)
        let pitches: [UInt8] = emulation.isPercussion ? [36, 38, 42] : [60, 64, 67]
        for (index, pitch) in pitches.enumerated() {
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(index * 140))
                engine.noteOn(pitch, velocity: 100, family: emulation.family)
                try? await Task.sleep(for: .milliseconds(500))
                engine.noteOff(pitch, family: emulation.family)
            }
        }
    }
}

/// Shared row for the emulation picker and the Instruments tab.
struct EmulationRow: View {
    let emulation: Emulation
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 8)
                .fill(DuoTheme.surfaceSecondary)
                .frame(width: 56, height: 56)
                .overlay {
                    Image(systemName: emulation.kind == .midi ? "waveform" : emulation.family.symbol)
                        .font(.title3.weight(.light))
                        .foregroundStyle(emulation.kind == .midi ? DuoTheme.accent : emulation.family.tint)
                }
            VStack(alignment: .leading, spacing: 3) {
                Text(emulation.name)
                    .font(.headline)
                    .foregroundStyle(DuoTheme.textPrimary)
                Text(emulation.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(DuoTheme.textSecondary)
            }
            Spacer()
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(DuoTheme.accent)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}
