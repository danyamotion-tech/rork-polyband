import SwiftUI

/// Track headers plus a scrolling bar grid with regions and playhead.
struct TimelineView: View {
    let model: SequencerViewModel

    private let headerWidth: CGFloat = 132
    private let rulerHeight: CGFloat = 22
    private let pointsPerBeat: CGFloat = 22

    var body: some View {
        GeometryReader { proxy in
            let rowHeight = max(44, (proxy.size.height - rulerHeight) / CGFloat(max(model.project.tracks.count, 1)))
            HStack(spacing: 0) {
                headers(rowHeight: rowHeight)
                    .frame(width: headerWidth)
                Rectangle().fill(DuoTheme.hairline).frame(width: DuoTheme.hairlineWidth)
                ScrollViewReader { reader in
                    ScrollView(.horizontal, showsIndicators: false) {
                        grid(rowHeight: rowHeight)
                            .frame(width: CGFloat(model.project.loopBeats) * pointsPerBeat + 40)
                    }
                    .onChange(of: Int(model.positionBeats / 8)) { _, chunk in
                        guard model.isPlaying else { return }
                        withAnimation(.easeInOut(duration: 0.25)) {
                            reader.scrollTo("bar-\(chunk * 2)", anchor: .leading)
                        }
                    }
                }
            }
        }
    }

    private func headers(rowHeight: CGFloat) -> some View {
        VStack(spacing: 0) {
            Color.clear.frame(height: rulerHeight)
            ForEach(model.project.tracks) { track in
                TrackHeader(track: track, isSelected: track.family == model.selectedFamily) {
                    model.select(track.family)
                } onMute: {
                    model.toggleMute(track.id)
                } onSolo: {
                    model.toggleSolo(track.id)
                }
                .frame(height: rowHeight)
                .overlay(alignment: .bottom) {
                    Rectangle().fill(DuoTheme.hairline).frame(height: DuoTheme.hairlineWidth)
                }
            }
        }
    }

    private func grid(rowHeight: CGFloat) -> some View {
        let beatsPerBar = model.project.beatsPerBar
        let bars = Int(model.project.loopBeats) / beatsPerBar
        return ZStack(alignment: .topLeading) {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    ForEach(0..<bars, id: \.self) { bar in
                        Text("\(bar + 1)")
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundStyle(DuoTheme.textSecondary)
                            .frame(width: pointsPerBeat * CGFloat(beatsPerBar), alignment: .leading)
                            .padding(.leading, 4)
                            .id("bar-\(bar)")
                    }
                }
                .frame(height: rulerHeight)
                ForEach(model.project.tracks) { track in
                    TrackLane(model: model, track: track, isSelected: track.family == model.selectedFamily, recordingRegionActive: model.isRecording && track.family == model.selectedFamily, pointsPerBeat: pointsPerBeat)
                        .frame(height: rowHeight)
                        .overlay(alignment: .bottom) {
                            Rectangle().fill(DuoTheme.hairline).frame(height: DuoTheme.hairlineWidth)
                        }
                }
            }
            GridLines(beatsPerBar: beatsPerBar, totalBeats: Int(model.project.loopBeats), pointsPerBeat: pointsPerBeat)
                .allowsHitTesting(false)
            Rectangle()
                .fill(DuoTheme.accent)
                .frame(width: 1.5)
                .overlay(alignment: .top) {
                    Triangle().fill(DuoTheme.accent).frame(width: 10, height: 7).offset(y: 2)
                }
                .offset(x: CGFloat(model.positionBeats) * pointsPerBeat)
                .allowsHitTesting(false)
        }
    }
}

private struct GridLines: View {
    let beatsPerBar: Int
    let totalBeats: Int
    let pointsPerBeat: CGFloat

    var body: some View {
        Canvas { context, size in
            for beat in 0...totalBeats {
                let x = CGFloat(beat) * pointsPerBeat
                let isBar = beat % beatsPerBar == 0
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(path, with: .color(isBar ? DuoTheme.hairline : DuoTheme.hairline.opacity(0.45)), lineWidth: 1)
            }
        }
    }
}

private struct Triangle: Shape {
    nonisolated func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct TrackHeader: View {
    let track: Track
    let isSelected: Bool
    let onSelect: () -> Void
    let onMute: () -> Void
    let onSolo: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: track.family.symbol)
                .font(.body.weight(.light))
                .foregroundStyle(track.family.tint)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 5) {
                Text(track.family.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isSelected ? DuoTheme.textPrimary : DuoTheme.textPrimary.opacity(0.85))
                    .lineLimit(1)
                Text(track.emulation.name)
                    .font(.caption2)
                    .foregroundStyle(DuoTheme.textSecondary)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    MiniToggle(title: "M", isOn: track.isMuted, activeColor: DuoTheme.textSecondary, action: onMute)
                    MiniToggle(title: "S", isOn: track.isSoloed, activeColor: DuoTheme.accent, action: onSolo)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .background(isSelected ? DuoTheme.surface : Color.clear)
        .overlay(alignment: .leading) {
            if isSelected {
                Rectangle().fill(DuoTheme.accent).frame(width: 2)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(track.family.title) track, \(track.emulation.name)")
    }
}

private struct MiniToggle: View {
    let title: String
    let isOn: Bool
    let activeColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(isOn ? DuoTheme.canvas : DuoTheme.textSecondary)
                .frame(width: 22, height: 18)
                .background(isOn ? activeColor : DuoTheme.surfaceSecondary, in: .rect(cornerRadius: 4))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title == "M" ? "Mute" : "Solo")
    }
}

/// One horizontal lane of regions.
private struct TrackLane: View {
    let model: SequencerViewModel
    let track: Track
    let isSelected: Bool
    let recordingRegionActive: Bool
    let pointsPerBeat: CGFloat

    var body: some View {
        ZStack(alignment: .leading) {
            if isSelected {
                DuoTheme.surface.opacity(0.6)
            }
            if track.emulation.kind == .midi, track.emulation.isPercussion, track.drumPattern.values.contains(where: { $0.contains(true) }) {
                PatternGhost(pattern: track.drumPattern, totalBeats: model.project.loopBeats, tint: track.family.tint, pointsPerBeat: pointsPerBeat)
                    .padding(.vertical, 6)
                    .allowsHitTesting(false)
                    .accessibilityLabel("Drum machine pattern, looping")
            }
            ForEach(track.regions) { region in
                DraggableRegion(
                    model: model,
                    trackID: track.id,
                    region: region,
                    tint: track.family.tint,
                    isRecording: recordingRegionActive && region.id == track.regions.last?.id,
                    pointsPerBeat: pointsPerBeat
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// The live drum-machine pattern, repeated across the lane as a dashed ghost so it is visible before it is printed.
private struct PatternGhost: View {
    let pattern: [Int: [Bool]]
    let totalBeats: Double
    let tint: Color
    let pointsPerBeat: CGFloat

    var body: some View {
        Canvas { context, size in
            let patternWidth = pointsPerBeat * 4
            let blocks = Int((totalBeats / 4).rounded(.up))
            let rows = pattern.keys.sorted()
            for block in 0..<blocks {
                let rect = CGRect(x: CGFloat(block) * patternWidth + 1, y: 0, width: patternWidth - 2, height: size.height).insetBy(dx: 0.5, dy: 0.5)
                let shape = Path(roundedRect: rect, cornerRadius: 4)
                context.fill(shape, with: .color(tint.opacity(0.08)))
                context.stroke(shape, with: .color(tint.opacity(0.55)), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                let stepWidth = (rect.width - 4) / 16
                for (rowIndex, pitch) in rows.enumerated() {
                    guard let row = pattern[pitch] else { continue }
                    let normalized = rows.count > 1 ? CGFloat(rowIndex) / CGFloat(rows.count - 1) : 0.5
                    let y = rect.maxY - 5 - normalized * (rect.height - 10)
                    for (step, isOn) in row.enumerated() where isOn {
                        let x = rect.minX + 2 + CGFloat(step) * stepWidth
                        context.fill(Path(CGRect(x: x, y: y, width: max(2, stepWidth - 1.5), height: 2)), with: .color(tint.opacity(0.7)))
                    }
                }
            }
            if let first = rows.first, pattern[first] != nil {
                context.draw(
                    Text("PATTERN").font(.system(size: 7, weight: .semibold, design: .rounded)).foregroundStyle(tint.opacity(0.8)),
                    at: CGPoint(x: 6, y: 5),
                    anchor: .topLeading
                )
            }
        }
        .frame(width: CGFloat(totalBeats) * pointsPerBeat)
    }
}

/// A region that lifts on long press and slides along the lane, snapping to beats.
private struct DraggableRegion: View {
    let model: SequencerViewModel
    let trackID: UUID
    let region: Region
    let tint: Color
    let isRecording: Bool
    let pointsPerBeat: CGFloat

    @State private var dragTranslation: CGFloat = 0
    @State private var isLifted = false

    private var snappedOffset: CGFloat {
        let target = max(0, (Double(region.startBeat) + Double(dragTranslation / pointsPerBeat)).rounded())
        return CGFloat(target - region.startBeat) * pointsPerBeat
    }

    var body: some View {
        RegionView(region: region, tint: tint, isRecording: isRecording)
            .frame(width: max(8, CGFloat(region.lengthBeats) * pointsPerBeat - 2))
            .padding(.vertical, isLifted ? 3 : 6)
            .shadow(color: .black.opacity(isLifted ? 0.5 : 0), radius: isLifted ? 8 : 0, y: isLifted ? 4 : 0)
            .offset(x: CGFloat(region.startBeat) * pointsPerBeat + 1 + (isLifted ? snappedOffset : 0))
            .zIndex(isLifted ? 1 : 0)
            .animation(.spring(duration: 0.2), value: isLifted)
            .animation(.interactiveSpring(duration: 0.12), value: snappedOffset)
            .gesture(moveGesture)
            .accessibilityLabel("Region at bar \(Int(region.startBeat / 4) + 1)")
            .accessibilityHint("Long press and drag to move")
    }

    private var moveGesture: some Gesture {
        LongPressGesture(minimumDuration: 0.22)
            .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .local))
            .onChanged { value in
                switch value {
                case .second(true, let drag):
                    if !isLifted {
                        isLifted = true
                        model.liftFeedback()
                    }
                    dragTranslation = drag?.translation.width ?? 0
                default:
                    break
                }
            }
            .onEnded { value in
                if case .second(true, let drag?) = value, !isRecording {
                    let beat = region.startBeat + Double(drag.translation.width / pointsPerBeat)
                    model.moveRegion(trackID: trackID, regionID: region.id, toStartBeat: beat)
                }
                dragTranslation = 0
                isLifted = false
            }
    }
}

private struct RegionView: View {
    let region: Region
    let tint: Color
    let isRecording: Bool

    var body: some View {
        Canvas { context, size in
            let rect = CGRect(origin: .zero, size: size)
            let shape = Path(roundedRect: rect.insetBy(dx: 0.5, dy: 0.5), cornerRadius: 4)
            context.fill(shape, with: .color(tint.opacity(0.2)))
            context.stroke(shape, with: .color(isRecording ? DuoTheme.record : tint.opacity(0.9)), lineWidth: 1)
            guard !region.notes.isEmpty else { return }
            let pitches = region.notes.map { Int($0.pitch) }
            let low = pitches.min() ?? 0
            let high = max(pitches.max() ?? 1, low + 1)
            for note in region.notes {
                let x = CGFloat(note.startBeat / region.lengthBeats) * size.width
                let width = max(2, CGFloat(note.duration / region.lengthBeats) * size.width - 1)
                let normalized = CGFloat(Int(note.pitch) - low) / CGFloat(high - low)
                let y = size.height - 5 - normalized * (size.height - 10)
                context.fill(Path(CGRect(x: x + 1, y: y, width: width, height: 2)), with: .color(tint.opacity(0.95)))
            }
        }
    }
}
