import SwiftUI

/// The main sequencer: timeline on top, live instrument below.
struct SequencerView: View {
    @Environment(ProjectStore.self) private var store
    @Environment(AudioEngine.self) private var engine
    @State private var model: SequencerViewModel?
    @State private var showsTempo = false

    let project: Project

    var body: some View {
        Group {
            if let model {
                content(model)
            } else {
                DuoTheme.canvas.ignoresSafeArea()
            }
        }
        .task {
            if model == nil {
                model = SequencerViewModel(project: project, store: store, engine: engine)
            }
        }
        .onDisappear { model?.stop() }
    }

    @ViewBuilder
    private func content(_ model: SequencerViewModel) -> some View {
        @Bindable var model = model
        ZStack {
            DuoTheme.canvas.ignoresSafeArea()
            VStack(spacing: 0) {
                topPane(model).frame(maxWidth: .infinity, maxHeight: .infinity)
                Rectangle().fill(DuoTheme.hairline).frame(height: DuoTheme.hairlineWidth)
                bottomPane(model).frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle(model.project.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Toggle(isOn: $model.isMetronomeOn) {
                        Label("Metronome", systemImage: "metronome")
                    }
                    Button {
                        showsTempo = true
                    } label: {
                        Label("Tempo", systemImage: "speedometer")
                    }
                    Button(role: .destructive) {
                        model.clearSelectedTrack()
                    } label: {
                        Label("Clear \(model.selectedFamily.title) Track", systemImage: "trash")
                    }
                } label: {
                    Label("More", systemImage: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $model.isPickingEmulation) {
            EmulationPickerView(model: model)
        }
        .sheet(isPresented: $showsTempo) {
            TempoSheet(model: model)
                .presentationDetents([.height(220)])
        }
    }

    private func topPane(_ model: SequencerViewModel) -> some View {
        VStack(spacing: 0) {
            TransportBar(model: model)
            TimelineView(model: model)
        }
    }

    private func bottomPane(_ model: SequencerViewModel) -> some View {
        VStack(spacing: 0) {
            InstrumentSelectorBar(model: model)
            InstrumentSurface(model: model)
        }
    }
}

private struct TempoSheet: View {
    @Bindable var model: SequencerViewModel

    var body: some View {
        VStack(spacing: 20) {
            Text("\(Int(model.project.bpm)) BPM")
                .font(.system(.largeTitle, design: .monospaced).weight(.semibold))
                .foregroundStyle(DuoTheme.textPrimary)
            Slider(value: Binding(get: { model.project.bpm }, set: { model.setBPM($0.rounded()) }), in: 40...240, step: 1)
                .padding(.horizontal, 24)
            Text("Tempo").font(.caption).foregroundStyle(DuoTheme.textSecondary)
        }
        .padding(.top, 28)
        .presentationBackground(DuoTheme.surface)
    }
}
