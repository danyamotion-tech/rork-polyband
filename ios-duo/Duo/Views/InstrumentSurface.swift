import SwiftUI

/// Bottom half: routes to the playable surface for the selected track.
struct InstrumentSurface: View {
    let model: SequencerViewModel

    var body: some View {
        let emulation = model.selectedTrack.emulation
        let style = EmulationStyle.style(for: emulation)
        Group {
            switch model.selectedFamily {
            case .drums:
                if emulation.kind == .midi {
                    DrumMachineSurface(model: model, style: style)
                } else {
                    RealDrumSurface(model: model, style: style)
                }
            case .keys:
                KeyboardSurface(model: model, style: style)
            case .guitar:
                FretboardSurface(model: model, style: style, stringPitches: [64, 59, 55, 50, 45, 40])
            case .bass:
                FretboardSurface(model: model, style: style, stringPitches: [43, 38, 33, 28])
            case .brass:
                BrassSurface(model: model, style: style)
            }
        }
        .id(emulation.id)
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.2), value: emulation.id)
    }
}

/// A pad that fires noteOn on touch-down and noteOff on release.
struct HoldPad<Content: View>: View {
    let onDown: () -> Void
    let onUp: () -> Void
    @ViewBuilder let content: (Bool) -> Content
    @State private var isPressed = false

    var body: some View {
        content(isPressed)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        guard !isPressed else { return }
                        isPressed = true
                        onDown()
                    }
                    .onEnded { _ in
                        isPressed = false
                        onUp()
                    }
            )
    }
}

// MARK: - Real drums

/// Photographic kit; shells are tinted to the selected kit's finish, hit zones sit over each drum.
struct RealDrumSurface: View {
    let model: SequencerViewModel
    let style: EmulationStyle

    private struct Zone: Identifiable {
        let id: String
        let pitch: UInt8
        let rect: CGRect
    }

    private let zones: [Zone] = [
        Zone(id: "hihat", pitch: 42, rect: CGRect(x: 0.01, y: 0.24, width: 0.19, height: 0.14)),
        Zone(id: "crash", pitch: 49, rect: CGRect(x: 0.14, y: 0.02, width: 0.24, height: 0.16)),
        Zone(id: "ride", pitch: 51, rect: CGRect(x: 0.69, y: 0.09, width: 0.29, height: 0.20)),
        Zone(id: "tom1", pitch: 48, rect: CGRect(x: 0.34, y: 0.17, width: 0.17, height: 0.14)),
        Zone(id: "tom2", pitch: 47, rect: CGRect(x: 0.53, y: 0.17, width: 0.17, height: 0.14)),
        Zone(id: "snare", pitch: 38, rect: CGRect(x: 0.17, y: 0.33, width: 0.21, height: 0.15)),
        Zone(id: "floor", pitch: 45, rect: CGRect(x: 0.68, y: 0.34, width: 0.24, height: 0.20)),
        Zone(id: "kick", pitch: 36, rect: CGRect(x: 0.36, y: 0.42, width: 0.30, height: 0.48)),
    ]

    private let imageAspect: CGFloat = 1536.0 / 1024.0

    private func imageFrame(in size: CGSize) -> CGRect {
        let viewAspect = size.width / size.height
        if viewAspect > imageAspect {
            let height = size.width / imageAspect
            return CGRect(x: 0, y: (size.height - height) / 2, width: size.width, height: height)
        } else {
            let width = size.height * imageAspect
            return CGRect(x: (size.width - width) / 2, y: 0, width: width, height: size.height)
        }
    }

    var body: some View {
        GeometryReader { proxy in
            let image = imageFrame(in: proxy.size)
            ZStack {
                DuoTheme.canvas
                    .overlay {
                        Image("drum_kit_front_view")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .allowsHitTesting(false)
                    }
                    .overlay {
                        // Kit finish tint: colour-grades the photo toward the emulation's shell colour.
                        style.body.opacity(0.28).blendMode(.color)
                        style.panel.opacity(0.18).blendMode(.multiply)
                    }
                    .clipped()
                ForEach(zones) { zone in
                    let frame = CGRect(
                        x: image.minX + zone.rect.minX * image.width,
                        y: image.minY + zone.rect.minY * image.height,
                        width: zone.rect.width * image.width,
                        height: zone.rect.height * image.height
                    )
                    HoldPad {
                        model.noteOn(zone.pitch, velocity: 110)
                    } onUp: {
                        model.noteOff(zone.pitch)
                    } content: { pressed in
                        Ellipse()
                            .fill(style.hardware.opacity(pressed ? 0.3 : 0))
                            .overlay {
                                Ellipse().stroke(DuoTheme.accent.opacity(pressed ? 0.9 : 0), lineWidth: 1)
                            }
                            .scaleEffect(pressed ? 1.04 : 1)
                            .animation(.spring(duration: 0.18), value: pressed)
                    }
                    .frame(width: frame.width, height: frame.height)
                    .position(x: frame.midX, y: frame.midY)
                    .accessibilityLabel(zone.id.capitalized)
                    .accessibilityAddTraits(.isButton)
                }
            }
            .overlay(alignment: .bottomTrailing) {
                NamePlate(text: style.plate, foreground: style.hardware)
                    .padding(10)
                    .allowsHitTesting(false)
            }
        }
    }
}

// MARK: - Drum machines

/// Roland-style drum machine: 16 step buttons in the classic colour bands plus 4x4 pads.
struct DrumMachineSurface: View {
    let model: SequencerViewModel
    let style: EmulationStyle
    @State private var stepPad: DrumPad = DrumPad.grid[0]

    /// TR-808 step-button colours: red, orange, yellow, white in groups of four.
    private func stepColor(_ step: Int) -> Color {
        switch style.drumMachine {
        case .tr808:
            switch step / 4 {
            case 0: return Color(hex: 0xC8342A)
            case 1: return Color(hex: 0xE07B2A)
            case 2: return Color(hex: 0xE4C33A)
            default: return Color(hex: 0xE8E4DA)
            }
        case .tr909:
            return step / 4 % 2 == 0 ? Color(hex: 0xE4E4E0) : Color(hex: 0xE0662A)
        case .electro:
            return style.signature
        }
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack(alignment: .center) {
                NamePlate(text: style.plate, foreground: style.hardware, background: style.panel)
                Spacer()
                HStack(spacing: 4) {
                    ForEach(0..<4, id: \.self) { index in
                        Circle()
                            .fill(model.isPlaying && model.currentStep / 4 == index ? style.signature : style.panel)
                            .frame(width: 6, height: 6)
                    }
                }
                Text("PATTERN A")
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(style.hardware.opacity(0.7))
            }
            .padding(.horizontal, 14)
            .padding(.top, 10)

            VStack(spacing: 5) {
                HStack(spacing: 4) {
                    ForEach(0..<16, id: \.self) { step in
                        let active = model.isStepActive(pitch: stepPad.pitch, step: step)
                        let isCurrent = model.isPlaying && model.currentStep == step
                        Button {
                            model.toggleStep(pitch: stepPad.pitch, step: step)
                        } label: {
                            VStack(spacing: 3) {
                                Circle()
                                    .fill(active ? style.signature : style.panel)
                                    .overlay(Circle().stroke(isCurrent ? DuoTheme.textPrimary : Color.clear, lineWidth: 1))
                                    .frame(width: 6, height: 6)
                                    .shadow(color: active ? style.signature.opacity(0.7) : .clear, radius: 3)
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(stepColor(step).opacity(active ? 1 : 0.55))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 3)
                                            .stroke(Color.black.opacity(0.5), lineWidth: 1)
                                    }
                                    .frame(height: 30)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Step \(step + 1) \(stepPad.name)")
                        .accessibilityValue(active ? "on" : "off")
                    }
                }
                HStack(spacing: 0) {
                    ForEach(0..<16, id: \.self) { step in
                        Text("\(step + 1)")
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundStyle(style.hardware.opacity(0.6))
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.horizontal, 14)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                ForEach(DrumPad.grid) { pad in
                    HoldPad {
                        stepPad = pad
                        model.audition(pad.pitch, velocity: 110)
                    } onUp: {
                    } content: { pressed in
                        RoundedRectangle(cornerRadius: 6)
                            .fill(pressed ? style.signature.opacity(0.9) : style.panel)
                            .overlay {
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(stepPad.id == pad.id ? style.signature : Color.black.opacity(0.6), lineWidth: 1)
                            }
                            .overlay(alignment: .topLeading) {
                                Circle()
                                    .fill(stepPad.id == pad.id ? style.signature : style.hardware.opacity(0.25))
                                    .frame(width: 5, height: 5)
                                    .padding(6)
                            }
                            .overlay {
                                Text(pad.name.uppercased())
                                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                                    .tracking(0.8)
                                    .foregroundStyle(pressed ? DuoTheme.canvas : style.hardware)
                            }
                            .scaleEffect(pressed ? 0.97 : 1)
                            .animation(.spring(duration: 0.15), value: pressed)
                    }
                    .frame(minHeight: 44)
                    .frame(maxHeight: .infinity)
                    .accessibilityLabel(pad.name)
                    .accessibilityAddTraits(.isButton)
                }
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 10)
        }
        .background(style.body)
    }
}

// MARK: - Keys

/// Two-octave keyboard with a control panel styled after the original instrument.
struct KeyboardSurface: View {
    let model: SequencerViewModel
    let style: EmulationStyle
    @State private var octave: Int = 4

    private let whitePattern: [Int] = [0, 2, 4, 5, 7, 9, 11]
    private let blackPattern: [Int: CGFloat] = [1: 0.5, 3: 1.5, 6: 3.5, 8: 4.5, 10: 5.5]

    var body: some View {
        VStack(spacing: 0) {
            panel
                .frame(height: 52)
            keyboard
                .padding(.horizontal, 6)
                .padding(.bottom, 8)
        }
        .background(style.body)
    }

    private var panel: some View {
        HStack(spacing: 10) {
            Button { octave = max(1, octave - 1) } label: {
                Label("Octave down", systemImage: "chevron.left").labelStyle(.iconOnly).frame(width: 44, height: 44)
            }
            Text("C\(octave)")
                .font(.system(.footnote, design: .monospaced))
                .foregroundStyle(style.hardware)
            Button { octave = min(7, octave + 1) } label: {
                Label("Octave up", systemImage: "chevron.right").labelStyle(.iconOnly).frame(width: 44, height: 44)
            }
            Spacer(minLength: 4)
            panelDecoration
            NamePlate(text: style.plate, foreground: style.signature, background: style.panel.opacity(0.6))
        }
        .foregroundStyle(style.hardware)
        .padding(.horizontal, 10)
        .background(alignment: .bottom) {
            Rectangle().fill(style.panel).frame(height: 3)
        }
    }

    /// Signature hardware element per keyboard model.
    @ViewBuilder
    private var panelDecoration: some View {
        switch style.keyPanel {
        case .grand:
            Rectangle().fill(style.hardware).frame(width: 60, height: 1)
        case .rhodes:
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { _ in Knob(color: style.panel, size: 16) }
            }
        case .wurlitzer:
            HStack(spacing: 8) {
                ForEach(0..<2, id: \.self) { _ in Knob(color: style.panel, size: 16) }
                Circle().fill(style.signature.opacity(0.3)).frame(width: 14, height: 14)
            }
        case .organ:
            HStack(spacing: 3) {
                ForEach(0..<9, id: \.self) { index in
                    Capsule()
                        .fill(index < 2 ? Color(hex: 0x7A3A2A) : (index < 6 ? Color(hex: 0xE6E1D3) : Color(hex: 0x1A1A1A)))
                        .frame(width: 6, height: 8 + CGFloat(index % 4) * 4)
                }
            }
        case .clavinet:
            HStack(spacing: 4) {
                ForEach(0..<4, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2).fill(index % 2 == 0 ? style.signature : style.hardware).frame(width: 12, height: 18)
                }
            }
        case .juno:
            HStack(spacing: 3) {
                ForEach(0..<8, id: \.self) { index in
                    Capsule().fill(style.hardware.opacity(0.5)).frame(width: 3, height: 22)
                        .overlay(alignment: .top) {
                            RoundedRectangle(cornerRadius: 1).fill(style.signature).frame(width: 7, height: 5)
                                .offset(y: CGFloat((index * 5) % 14))
                        }
                }
            }
        case .moog:
            HStack(spacing: 5) {
                ForEach(0..<4, id: \.self) { _ in Knob(color: Color(hex: 0x141414), size: 18, indicator: style.signature) }
            }
        case .dx:
            HStack(spacing: 3) {
                ForEach(0..<6, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 1).fill(index == 2 ? style.signature : style.hardware.opacity(0.5)).frame(width: 10, height: 7)
                }
            }
        }
    }

    private var keyboard: some View {
        GeometryReader { proxy in
            let whiteCount = 14
            let whiteWidth = proxy.size.width / CGFloat(whiteCount)
            let base = UInt8((octave + 1) * 12)
            ZStack(alignment: .topLeading) {
                HStack(spacing: 1) {
                    ForEach(0..<whiteCount, id: \.self) { index in
                        let pitch = base + UInt8(whitePattern[index % 7] + (index / 7) * 12)
                        HoldPad {
                            model.noteOn(pitch, velocity: 100)
                        } onUp: {
                            model.noteOff(pitch)
                        } content: { pressed in
                            key(isBlack: false, pressed: pressed)
                        }
                        .accessibilityLabel("Key \(pitch)")
                    }
                }
                ForEach(0..<2, id: \.self) { octaveIndex in
                    ForEach(blackPattern.sorted(by: { $0.key < $1.key }), id: \.key) { semitone, position in
                        let pitch = base + UInt8(semitone + octaveIndex * 12)
                        HoldPad {
                            model.noteOn(pitch, velocity: 100)
                        } onUp: {
                            model.noteOff(pitch)
                        } content: { pressed in
                            key(isBlack: true, pressed: pressed)
                        }
                        .frame(width: whiteWidth * 0.62, height: proxy.size.height * 0.6)
                        .offset(x: (CGFloat(octaveIndex * 7) + position + 0.5) * whiteWidth - whiteWidth * 0.31)
                        .accessibilityLabel("Key \(pitch)")
                    }
                }
            }
        }
    }

    private var isFlatSynth: Bool {
        switch style.keyPanel {
        case .juno, .moog, .dx: true
        default: false
        }
    }

    private func key(isBlack: Bool, pressed: Bool) -> some View {
        let radius: CGFloat = isFlatSynth ? 2 : 3
        let shape = UnevenRoundedRectangle(bottomLeadingRadius: radius, bottomTrailingRadius: radius)
        return shape
            .fill(pressed ? DuoTheme.accent.opacity(isBlack ? 0.9 : 0.75) : (isBlack ? style.blackKey : style.whiteKey))
            .overlay(alignment: .bottom) {
                if !isFlatSynth && !isBlack {
                    shape.fill(LinearGradient(colors: [.clear, .black.opacity(0.18)], startPoint: .top, endPoint: .bottom))
                }
            }
            .overlay { shape.stroke(Color.black.opacity(0.6), lineWidth: 1) }
            .shadow(color: isBlack && !isFlatSynth ? .black.opacity(0.6) : .clear, radius: 3, y: 2)
            .animation(.easeOut(duration: 0.08), value: pressed)
    }
}

private struct Knob: View {
    let color: Color
    let size: CGFloat
    var indicator: Color = Color(hex: 0xE8E4DA)

    var body: some View {
        Circle()
            .fill(color)
            .overlay(Circle().stroke(Color.black.opacity(0.5), lineWidth: 1))
            .overlay(alignment: .top) {
                Capsule().fill(indicator).frame(width: 2, height: size * 0.35).padding(.top, 2)
            }
            .frame(width: size, height: size)
    }
}

// MARK: - Fretboard

/// Fretboard drawn from the original instrument: body finish, pickguard, pickups, inlays, frets.
struct FretboardSurface: View {
    let model: SequencerViewModel
    let style: EmulationStyle
    /// Open-string pitches, high string first (top of screen).
    let stringPitches: [UInt8]
    private let frets = 8
    private let bodyWidth: CGFloat = 96

    var body: some View {
        GeometryReader { proxy in
            let neckWidth = proxy.size.width - bodyWidth
            let stringHeight = proxy.size.height / CGFloat(stringPitches.count)
            let fretWidth = neckWidth / CGFloat(frets)
            HStack(spacing: 0) {
                neck(fretWidth: fretWidth, stringHeight: stringHeight, height: proxy.size.height)
                    .frame(width: neckWidth)
                bodySection(stringHeight: stringHeight)
                    .frame(width: bodyWidth)
            }
        }
        .background(DuoTheme.canvas)
    }

    private func neck(fretWidth: CGFloat, stringHeight: CGFloat, height: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            style.panel
            fretMarkers(fretWidth: fretWidth, height: height)
            VStack(spacing: 0) {
                ForEach(Array(stringPitches.enumerated()), id: \.offset) { stringIndex, open in
                    HStack(spacing: 0) {
                        ForEach(0..<frets, id: \.self) { fret in
                            let pitch = open + UInt8(fret)
                            HoldPad {
                                model.noteOn(pitch, velocity: UInt8(90 + fret))
                            } onUp: {
                                model.noteOff(pitch)
                            } content: { pressed in
                                ZStack {
                                    Color.clear
                                    Rectangle()
                                        .fill(style.stringColor.opacity(0.75))
                                        .frame(height: 1 + CGFloat(stringIndex) * 0.45)
                                        .shadow(color: .black.opacity(0.7), radius: 1, y: 1)
                                    Circle()
                                        .fill(DuoTheme.accent.opacity(pressed ? 0.75 : 0))
                                        .frame(width: min(stringHeight, fretWidth) * 0.55)
                                        .animation(.easeOut(duration: 0.12), value: pressed)
                                }
                            }
                            .frame(width: fretWidth, height: stringHeight)
                            .accessibilityLabel("String \(stringIndex + 1) fret \(fret)")
                        }
                    }
                }
            }
            HStack(spacing: 0) {
                ForEach(0..<frets, id: \.self) { fret in
                    Rectangle()
                        .fill(fret == 0 ? Color(hex: 0xEFE7D2) : (style.hasFretWire ? style.hardware : style.hardware.opacity(0.25)))
                        .frame(width: fret == 0 ? 4 : (style.hasFretWire ? 2 : 1))
                        .frame(width: fretWidth, alignment: .leading)
                }
            }
            .allowsHitTesting(false)
        }
    }

    /// Inlays at frets 3, 5 and 7 in the model's style.
    private func fretMarkers(fretWidth: CGFloat, height: CGFloat) -> some View {
        HStack(spacing: 0) {
            ForEach(0..<frets, id: \.self) { fret in
                ZStack {
                    if [3, 5, 7].contains(fret) {
                        switch style.inlay {
                        case .dot:
                            Circle().fill(Color(hex: 0xEFE7D2).opacity(0.8)).frame(width: 9, height: 9)
                        case .trapezoid:
                            Trapezoid().fill(Color(hex: 0xEFE7D2).opacity(0.85)).frame(width: fretWidth * 0.55, height: height * 0.5)
                        case .block:
                            RoundedRectangle(cornerRadius: 2).fill(Color(hex: 0xEFE7D2).opacity(0.85)).frame(width: fretWidth * 0.5, height: height * 0.55)
                        case .none:
                            EmptyView()
                        }
                    }
                }
                .frame(width: fretWidth)
            }
        }
        .frame(height: height)
        .allowsHitTesting(false)
    }

    /// Slice of the body next to the neck: finish, pickguard, pickup or soundhole, nameplate.
    private func bodySection(stringHeight: CGFloat) -> some View {
        ZStack(alignment: .leading) {
            style.body
            LinearGradient(colors: [.black.opacity(0.35), .clear, .black.opacity(0.25)], startPoint: .top, endPoint: .bottom)
            pickupGraphic
                .frame(maxWidth: .infinity)
            VStack(spacing: 0) {
                ForEach(Array(stringPitches.enumerated()), id: \.offset) { stringIndex, _ in
                    Rectangle()
                        .fill(style.stringColor.opacity(0.75))
                        .frame(height: 1 + CGFloat(stringIndex) * 0.45)
                        .frame(height: stringHeight)
                }
            }
        }
        .overlay(alignment: .bottomTrailing) {
            NamePlate(text: style.plate, foreground: style.signature)
                .padding(6)
        }
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private var pickupGraphic: some View {
        switch style.pickup {
        case .humbucker:
            RoundedRectangle(cornerRadius: 3)
                .fill(style.hardware)
                .frame(width: 22, height: stringPitches.count == 4 ? 120 : 150)
                .overlay {
                    VStack(spacing: 6) {
                        ForEach(0..<6, id: \.self) { _ in Circle().fill(Color.black.opacity(0.6)).frame(width: 4, height: 4) }
                    }
                }
        case .singleCoil:
            Capsule()
                .fill(Color(hex: 0xF1EBDD))
                .frame(width: 14, height: stringPitches.count == 4 ? 120 : 150)
                .overlay {
                    VStack(spacing: 7) {
                        ForEach(0..<6, id: \.self) { _ in Circle().fill(style.hardware).frame(width: 4, height: 4) }
                    }
                }
                .background(alignment: .center) {
                    RoundedRectangle(cornerRadius: 10).fill(style.panel).frame(width: 60, height: 200).offset(x: 10)
                }
        case .split:
            VStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 3).fill(Color(hex: 0x141414)).frame(width: 22, height: 44)
                RoundedRectangle(cornerRadius: 3).fill(Color(hex: 0x141414)).frame(width: 22, height: 44)
            }
            .offset(x: -6)
            .background { RoundedRectangle(cornerRadius: 12).fill(style.panel).frame(width: 64, height: 200).offset(x: 10) }
        case .soundhole:
            Circle()
                .fill(Color(hex: 0x1A100A))
                .frame(width: 72, height: 72)
                .overlay(Circle().stroke(style.panel, lineWidth: 5))
                .overlay(Circle().stroke(Color(hex: 0xEFE7D2).opacity(0.5), lineWidth: 1).padding(4))
        case .fHole:
            HStack(spacing: 40) {
                FHole().fill(Color(hex: 0x120A06)).frame(width: 12, height: 70)
            }
        case .none:
            EmptyView()
        }
    }
}

private struct Trapezoid: Shape {
    nonisolated func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.2, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.2, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct FHole: Shape {
    nonisolated func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addEllipse(in: CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: rect.width))
        path.addEllipse(in: CGRect(x: rect.minX, y: rect.maxY - rect.width, width: rect.width, height: rect.width))
        path.addRect(CGRect(x: rect.midX - rect.width * 0.18, y: rect.minY + rect.width * 0.5, width: rect.width * 0.36, height: rect.height - rect.width))
        return path
    }
}

// MARK: - Brass

/// Lacquered brass surface with model-specific controls: piston valves, slide, rotary valves or sax keys.
struct BrassSurface: View {
    let model: SequencerViewModel
    let style: EmulationStyle
    private let scale: [(String, UInt8)] = [("C", 60), ("D", 62), ("E", 64), ("F", 65), ("G", 67), ("A", 69), ("Bb", 70), ("C", 72)]

    var body: some View {
        VStack(spacing: 0) {
            LinearGradient(colors: [style.panel, style.body, style.panel.opacity(0.9)], startPoint: .top, endPoint: .bottom)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay {
                    Image("brass_trumpet_horizontal")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .opacity(style.brassControl == .valves || style.brassControl == .section ? 0.9 : 0.35)
                        .allowsHitTesting(false)
                }
                .clipped()
                .overlay {
                    controlGraphic
                        .padding(.horizontal, 16)
                        .allowsHitTesting(false)
                }
                .overlay(alignment: .topLeading) {
                    NamePlate(text: style.plate, foreground: style.hardware)
                        .padding(10)
                }
            GeometryReader { proxy in
                let spacing: CGFloat = 6
                let side = min(56, max(36, (proxy.size.width - 24 - spacing * CGFloat(scale.count - 1)) / CGFloat(scale.count)))
                HStack(spacing: spacing) {
                    ForEach(Array(scale.enumerated()), id: \.offset) { _, item in
                        HoldPad {
                            model.noteOn(item.1, velocity: 105)
                        } onUp: {
                            model.noteOff(item.1)
                        } content: { pressed in
                            valveButton(label: item.0, pressed: pressed)
                        }
                        .frame(width: side, height: side)
                        .frame(minHeight: 44)
                        .accessibilityLabel("Note \(item.0)")
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: proxy.size.height)
            }
            .frame(height: 76)
            .background(Color(hex: 0x111111))
        }
        .clipped()
    }

    /// Note buttons shaped like the original's fingering hardware.
    @ViewBuilder
    private func valveButton(label: String, pressed: Bool) -> some View {
        let fill = pressed ? DuoTheme.accent : style.hardware
        switch style.brassControl {
        case .saxKeys:
            Circle()
                .fill(fill)
                .overlay(Circle().fill(Color(hex: 0xE9DFC8).opacity(pressed ? 0 : 0.85)).padding(5))
                .overlay(Text(label).font(.system(size: 11, weight: .semibold, design: .rounded)).foregroundStyle(DuoTheme.canvas))
                .shadow(color: .black.opacity(0.5), radius: 2, y: 2)
                .scaleEffect(pressed ? 0.94 : 1)
                .animation(.spring(duration: 0.15), value: pressed)
        case .slide:
            RoundedRectangle(cornerRadius: 4)
                .fill(fill)
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.black.opacity(0.6), lineWidth: 1))
                .overlay(Text(label).font(.system(size: 11, weight: .semibold, design: .rounded)).foregroundStyle(DuoTheme.canvas))
                .offset(y: pressed ? 4 : 0)
                .animation(.spring(duration: 0.15), value: pressed)
        case .rotary:
            Circle()
                .fill(style.panel)
                .overlay(Circle().stroke(fill, lineWidth: 3))
                .overlay(Text(label).font(.system(size: 11, weight: .semibold, design: .rounded)).foregroundStyle(fill))
                .rotationEffect(.degrees(pressed ? 25 : 0))
                .animation(.spring(duration: 0.18), value: pressed)
        case .valves, .section:
            Circle()
                .fill(LinearGradient(colors: [fill, fill.opacity(0.7)], startPoint: .top, endPoint: .bottom))
                .overlay(Circle().fill(Color(hex: 0xF5F0E4).opacity(pressed ? 0 : 0.9)).padding(6))
                .overlay(Text(label).font(.system(size: 11, weight: .semibold, design: .rounded)).foregroundStyle(pressed ? DuoTheme.canvas : Color(hex: 0x3A2A10)))
                .shadow(color: .black.opacity(0.5), radius: 2, y: pressed ? 0 : 3)
                .offset(y: pressed ? 3 : 0)
                .animation(.spring(duration: 0.15), value: pressed)
        }
    }

    @ViewBuilder
    private var controlGraphic: some View {
        switch style.brassControl {
        case .slide:
            VStack(spacing: 14) {
                Capsule().fill(style.hardware).frame(height: 6)
                Capsule().fill(style.hardware).frame(height: 6)
            }
            .padding(.horizontal, 30)
            .overlay(alignment: .trailing) {
                Circle().fill(style.body).overlay(Circle().stroke(style.hardware, lineWidth: 2)).frame(width: 70, height: 70)
            }
        case .rotary:
            HStack(spacing: 18) {
                ForEach(0..<3, id: \.self) { _ in
                    Circle().stroke(style.hardware, lineWidth: 4).frame(width: 46, height: 46)
                }
            }
        case .saxKeys:
            HStack(spacing: 10) {
                ForEach(0..<6, id: \.self) { index in
                    Circle().fill(Color(hex: 0xE9DFC8)).overlay(Circle().stroke(style.hardware, lineWidth: 2)).frame(width: 22 + CGFloat(index % 3) * 4)
                }
            }
        case .valves, .section:
            EmptyView()
        }
    }
}
