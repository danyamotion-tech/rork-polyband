import SwiftUI

/// Editorial project library — the app's first screen.
struct ProjectsView: View {
    @Environment(ProjectStore.self) private var store
    @State private var searchText: String = ""
    @State private var path: [UUID] = []

    private var filtered: [Project] {
        guard !searchText.isEmpty else { return store.projects }
        return store.projects.filter { $0.name.localizedStandardContains(searchText) }
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack(alignment: .bottom) {
                DuoTheme.canvas.ignoresSafeArea()
                List {
                    ForEach(filtered) { project in
                        Button {
                            path.append(project.id)
                        } label: {
                            ProjectRow(project: project, isRecent: project.id == store.projects.first?.id)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(DuoTheme.canvas)
                        .listRowSeparatorTint(DuoTheme.hairline)
                        .listRowInsets(EdgeInsets(top: 14, leading: 20, bottom: 14, trailing: 16))
                        .swipeActions {
                            Button(role: .destructive) {
                                store.delete(project)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    Color.clear.frame(height: 72).listRowBackground(DuoTheme.canvas).listRowSeparator(.hidden)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .overlay {
                    if filtered.isEmpty {
                        ContentUnavailableView("No projects", systemImage: "waveform", description: Text("Create a project to start sketching."))
                    }
                }

                Button {
                    let project = store.createProject()
                    path.append(project.id)
                } label: {
                    Label("New Project", systemImage: "plus")
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
            .navigationTitle("Projects")
            .searchable(text: $searchText, prompt: "Search")
            .navigationDestination(for: UUID.self) { id in
                if let project = store.project(id: id) {
                    SequencerView(project: project)
                } else {
                    ContentUnavailableView("Project not found", systemImage: "questionmark.folder")
                }
            }
        }
    }
}

private struct ProjectRow: View {
    let project: Project
    let isRecent: Bool

    var body: some View {
        HStack(spacing: 14) {
            ProjectThumbnail(project: project)
                .frame(width: 88, height: 88)
                .clipShape(.rect(cornerRadius: DuoTheme.cornerRadius))
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text(project.name)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(DuoTheme.textPrimary)
                    if isRecent {
                        Circle().fill(DuoTheme.accent).frame(width: 7, height: 7)
                    }
                }
                WaveformStrip(seed: project.name.hashValue)
                    .frame(height: 22)
                Text("\(Int(project.bpm)) BPM · \(project.populatedTrackCount) \(project.populatedTrackCount == 1 ? "track" : "tracks") · \(project.lastEdited.duoRelative)")
                    .font(.caption)
                    .foregroundStyle(DuoTheme.textSecondary)
            }
            Spacer(minLength: 4)
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(DuoTheme.textSecondary)
        }
        .contentShape(Rectangle())
    }
}

/// Miniature of the project's regions as thin tinted bars.
private struct ProjectThumbnail: View {
    let project: Project

    var body: some View {
        Canvas { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(DuoTheme.surface))
            let tracks = project.tracks
            let rowHeight = size.height / CGFloat(max(tracks.count, 1))
            let total = max(project.loopBeats, 1)
            for (index, track) in tracks.enumerated() {
                let y = CGFloat(index) * rowHeight + rowHeight * 0.3
                for region in track.regions {
                    let x = CGFloat(region.startBeat / total) * size.width
                    let width = CGFloat(region.lengthBeats / total) * size.width
                    let rect = CGRect(x: x + 6, y: y, width: max(2, width - 12), height: rowHeight * 0.4)
                    context.fill(Path(roundedRect: rect, cornerRadius: 1.5), with: .color(track.family.tint.opacity(0.85)))
                }
            }
        }
    }
}

/// Deterministic monochrome waveform decoration.
struct WaveformStrip: View {
    let seed: Int

    var body: some View {
        Canvas { context, size in
            var generator = SeededGenerator(seed: UInt64(bitPattern: Int64(seed)))
            let count = Int(size.width / 3)
            for index in 0..<count {
                let amplitude = CGFloat(Double.random(in: 0.15...1, using: &generator))
                let height = size.height * amplitude
                let rect = CGRect(x: CGFloat(index) * 3, y: (size.height - height) / 2, width: 1.5, height: height)
                context.fill(Path(rect), with: .color(DuoTheme.textSecondary.opacity(0.55)))
            }
        }
    }
}

nonisolated struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
    }

    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}

extension Date {
    /// "Yesterday", "Today" or a short month-day label.
    var duoRelative: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(self) { return "Today" }
        if calendar.isDateInYesterday(self) { return "Yesterday" }
        return formatted(.dateTime.month(.abbreviated).day())
    }
}
