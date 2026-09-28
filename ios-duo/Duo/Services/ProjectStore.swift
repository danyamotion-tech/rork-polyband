import Foundation
import Observation

/// Persists projects to disk and exposes them to the UI.
@Observable
final class ProjectStore {
    private(set) var projects: [Project] = []

    private let fileURL: URL = {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return directory.appendingPathComponent("duo-projects.json")
    }()

    init() {
        load()
    }

    func project(id: UUID) -> Project? {
        projects.first { $0.id == id }
    }

    @discardableResult
    func createProject(name: String? = nil, bpm: Double = 120) -> Project {
        let count = projects.count + 1
        let project = Project(
            name: name ?? "Project \(count)",
            bpm: bpm,
            tracks: InstrumentFamily.allCases.map { Track.make($0) },
            lastEdited: Date()
        )
        projects.insert(project, at: 0)
        save()
        return project
    }

    func update(_ project: Project) {
        guard let index = projects.firstIndex(where: { $0.id == project.id }) else { return }
        var updated = project
        updated.lastEdited = Date()
        projects[index] = updated
        projects.sort { $0.lastEdited > $1.lastEdited }
        save()
    }

    func delete(_ project: Project) {
        projects.removeAll { $0.id == project.id }
        save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([Project].self, from: data) else {
            projects = SampleData.projects
            save()
            return
        }
        projects = decoded.sorted { $0.lastEdited > $1.lastEdited }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(projects)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("[ProjectStore] save failed: \(error.localizedDescription)")
        }
    }
}
