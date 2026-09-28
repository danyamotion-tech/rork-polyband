import SwiftUI

/// Family segmented picker plus the current emulation button.
struct InstrumentSelectorBar: View {
    let model: SequencerViewModel

    var body: some View {
        HStack(spacing: 10) {
            Picker("Instrument", selection: Binding(get: { model.selectedFamily }, set: { model.select($0) })) {
                ForEach(InstrumentFamily.allCases) { family in
                    Text(family.title).tag(family)
                }
            }
            .pickerStyle(.segmented)
            .layoutPriority(1)

            Button {
                model.isPickingEmulation = true
            } label: {
                HStack(spacing: 4) {
                    Text(model.selectedTrack.emulation.name)
                        .lineLimit(1)
                    Image(systemName: "chevron.down")
                        .font(.caption2.weight(.semibold))
                }
                .font(.footnote.weight(.medium))
                .foregroundStyle(DuoTheme.textPrimary)
                .padding(.horizontal, 12)
                .frame(height: 32)
                .background(DuoTheme.surfaceSecondary, in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Choose emulation, current \(model.selectedTrack.emulation.name)")
        }
        .padding(.horizontal, 12)
        .frame(height: 52)
        .overlay(alignment: .bottom) {
            Rectangle().fill(DuoTheme.hairline).frame(height: DuoTheme.hairlineWidth)
        }
    }
}
