import SwiftUI

/// Library of ready-made loops that can be added to any project.
struct LoopsView: View {
    @Environment(ProjectStore.self) private var store
    @Environment(AudioEngine.self) private var engine
    @State private var loopToAdd: LoopPreset?

    var body: some View {
        NavigationStack {
            ZStack {
                DuoTheme.canvas.ignoresSafeArea()
                List {
                    ForEach(LoopPreset.all) { loop in
                        HStack(spacing: 14) {
                            LoopPreview(loop: loop)
                                .frame(width: 88, height: 44)
                                .clipShape(.rect(cornerRadius: 6))
                            VStack(alignment: .leading, spacing: 3) {
                                Text(loop.name)
                                    .font(.headline)
                                    .foregroundStyle(DuoTheme.textPrimary)
                                Text("\(loop.family.title) · \(EmulationCatalog.emulation(id: loop.emulationID)?.name ?? "") · \(loop.bars) \(loop.bars == 1 ? "bar" : "bars")")
                                    .font(.caption)
                                    .foregroundStyle(DuoTheme.textSecondary)
                            }
                            Spacer()
                            Button {
                                loopToAdd = loop
                            } label: {
                                Image(systemName: "plus")
                                    .font(.body.weight(.semibold))
                                    .frame(width: 44, height: 44)
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(DuoTheme.accent)
                            .accessibilityLabel("Add \(loop.name) to a project")
                        }
                        .padding(.vertical, 4)
                        .listRowBackground(DuoTheme.canvas)
                        .listRowSeparatorTint(DuoTheme.hairline)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Loops")
            .confirmationDialog("Add to project", isPresented: Binding(get: { loopToAdd != nil }, set: { if !$0 { loopToAdd = nil } }), titleVisibility: .visible) {
                ForEach(store.projects.prefix(6)) { project in
                    Button(project.name) {
                        if let loop = loopToAdd { add(loop, to: project) }
                    }
                }
                Button("New Project") {
                    if let loop = loopToAdd { add(loop, to: store.createProject()) }
                }
            }
        }
    }

    private func add(_ loop: LoopPreset, to project: Project) {
        let model = SequencerViewModel(project: project, store: store, engine: engine)
        model.addLoop(loop)
        loopToAdd = nil
    }
}

private struct LoopPreview: View {
    let loop: LoopPreset

    var body: some View {
        Canvas { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(DuoTheme.surface))
            let pitches = loop.notes.map { Int($0.pitch) }
            let low = pitches.min() ?? 0
            let high = max((pitches.max() ?? 1), low + 1)
            for note in loop.notes {
                let x = CGFloat(note.startBeat / loop.lengthBeats) * size.width
                let width = max(2, CGFloat(note.duration / loop.lengthBeats) * size.width - 1)
                let normalized = CGFloat(Int(note.pitch) - low) / CGFloat(high - low)
                let y = size.height - 4 - normalized * (size.height - 8)
                context.fill(Path(CGRect(x: x, y: y, width: width, height: 2)), with: .color(loop.family.tint))
            }
        }
    }
}
