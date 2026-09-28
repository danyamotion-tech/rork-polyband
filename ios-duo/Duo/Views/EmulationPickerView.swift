import SwiftUI

/// Sheet: pick a Real or MIDI emulation for the selected track.
struct EmulationPickerView: View {
    @Environment(\.dismiss) private var dismiss
    let model: SequencerViewModel
    @State private var kind: Emulation.Kind = .real
    @State private var selection: Emulation?

    private var family: InstrumentFamily { model.selectedFamily }
    private var items: [Emulation] { EmulationCatalog.emulations(for: family) }
    private var real: [Emulation] { items.filter { $0.kind == .real } }
    private var midi: [Emulation] { items.filter { $0.kind == .midi } }
    private var current: Emulation { selection ?? model.selectedTrack.emulation }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                DuoTheme.canvas.ignoresSafeArea()
                List {
                    if family.hasMIDIVariants {
                        Picker("Type", selection: $kind) {
                            Text("Real").tag(Emulation.Kind.real)
                            Text("MIDI").tag(Emulation.Kind.midi)
                        }
                        .pickerStyle(.segmented)
                        .listRowBackground(DuoTheme.canvas)
                        .listRowSeparator(.hidden)
                    }
                    if kind == .real || !family.hasMIDIVariants {
                        section("Real", real)
                    }
                    if family.hasMIDIVariants && (kind == .midi || kind == .real) {
                        section("MIDI Synths", midi)
                    }
                    Color.clear.frame(height: 70).listRowBackground(DuoTheme.canvas).listRowSeparator(.hidden)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)

                Button {
                    model.setEmulation(current)
                    dismiss()
                } label: {
                    Text("Use \(current.name)")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.roundedRectangle(radius: 14))
                .foregroundStyle(DuoTheme.canvas)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
            .navigationTitle(family.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(DuoTheme.canvas)
        .onAppear {
            kind = model.selectedTrack.emulation.kind
        }
    }

    @ViewBuilder
    private func section(_ title: String, _ list: [Emulation]) -> some View {
        Section {
            ForEach(list) { emulation in
                Button {
                    selection = emulation
                    audition(emulation)
                } label: {
                    EmulationRow(emulation: emulation, isSelected: emulation.id == current.id)
                }
                .buttonStyle(.plain)
                .listRowBackground(DuoTheme.canvas)
                .listRowSeparatorTint(DuoTheme.hairline)
            }
        } header: {
            Text(title).foregroundStyle(DuoTheme.textSecondary)
        }
    }

    private func audition(_ emulation: Emulation) {
        model.setEmulation(emulation)
        let pitch: UInt8 = emulation.isPercussion ? 38 : 64
        model.noteOn(pitch, velocity: 100)
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(400))
            model.noteOff(pitch)
        }
    }
}
