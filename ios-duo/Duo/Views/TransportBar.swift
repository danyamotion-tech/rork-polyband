import SwiftUI

/// Rewind / play / record plus the monospaced position readout.
struct TransportBar: View {
    let model: SequencerViewModel

    var body: some View {
        HStack(spacing: 18) {
            Button {
                model.rewind()
            } label: {
                Image(systemName: "backward.end")
                    .font(.title3.weight(.light))
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Rewind")

            Button {
                model.togglePlay()
            } label: {
                Image(systemName: model.isPlaying ? "pause.fill" : "play.fill")
                    .font(.title3)
                    .frame(width: 44, height: 44)
                    .contentTransition(.symbolEffect(.replace))
            }
            .accessibilityLabel(model.isPlaying ? "Pause" : "Play")

            Button {
                model.toggleRecord()
            } label: {
                Circle()
                    .fill(model.isRecording ? DuoTheme.record : DuoTheme.record.opacity(0.55))
                    .frame(width: 14, height: 14)
                    .overlay {
                        Circle().stroke(DuoTheme.record, lineWidth: 1.5).frame(width: 22, height: 22)
                    }
                    .shadow(color: model.isRecording ? DuoTheme.record.opacity(0.6) : .clear, radius: 6)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel(model.isRecording ? "Stop recording" : "Record")

            Text(model.positionLabel)
                .font(.system(.title3, design: .monospaced).weight(.medium))
                .foregroundStyle(DuoTheme.accent)
                .frame(minWidth: 90)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(DuoTheme.surface, in: .rect(cornerRadius: 8))
                .monospacedDigit()

            Spacer(minLength: 0)

            if model.isRecording {
                Text("REC")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(DuoTheme.record)
            } else {
                Text("\(Int(model.project.bpm)) BPM")
                    .font(.system(.footnote, design: .monospaced))
                    .foregroundStyle(DuoTheme.textSecondary)
            }
        }
        .foregroundStyle(DuoTheme.textPrimary)
        .padding(.horizontal, 12)
        .frame(height: 56)
        .overlay(alignment: .bottom) {
            Rectangle().fill(DuoTheme.hairline).frame(height: DuoTheme.hairlineWidth)
        }
    }
}
