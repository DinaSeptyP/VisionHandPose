//
//  HandTrackingExperienceView.swift
//  VisionHandPose
//
//  Created by Muhamad Yuan Sastro Dimianta on 16/07/26.
//

import SwiftUI

struct HandTrackingExperienceView: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var manager: HandPoseManager
    @ObservedObject var chordPlayer: ChordPlayer
    @State private var stringVibrations: [CGFloat] = [0, 0, 0, 0, 0, 0]
    @State private var lastTriggeredStrings: [Bool] = [false, false, false, false, false, false]
    @State private var stringYPositions: [CGFloat] = [0.35, 0.41, 0.47, 0.53, 0.59, 0.65]
    @State private var draggingString: Int? = nil
    @State private var dragStartPositions: [CGFloat] = Array(repeating: 0, count: 6)
    
    var body: some View {
        Group {
            if manager.cameraPermissionGranted {
                ZStack {
                    Color.black.opacity(0.2)
                        .ignoresSafeArea()
                    CameraPreviewView(session: manager.session)
                        .ignoresSafeArea()
                    
                    GeometryReader { geo in
                        let w = geo.size.width
                        let h = geo.size.height
                        
                        Path { path in
                            path.move(to: CGPoint(x: w * 0.5, y: 0))
                            path.addLine(to: CGPoint(x: w * 0.5, y: h))
                        }
                        .stroke(
                            LinearGradient(
                                colors: [.brown.opacity(0.1), .white.opacity(0.5), .brown.opacity(0.1)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            style: StrokeStyle(lineWidth: 1.5, dash: [8, 4])
                        )
                        
                        ZoneLabelView(
                            title: manager.isRightHanded ? "Chord" : "Strumming Pattern",
                            color: manager.isRightHanded ? Color("PrimaryBrown") : Color("SecondaryFont"),
                            x: w*0.25,
                            y: 25
                        )
                        ZoneLabelView(
                            title: manager.isRightHanded ? "Strumming Pattern" : "Chord",
                            color: manager.isRightHanded ? Color("SecondaryFont") : Color("PrimaryBrown"),
                            x: w*0.75,
                            y:25
                        )
                        
                        let chordStartX = manager.isRightHanded ? CGFloat(0) : w * 0.52
                        let chordEndX = manager.isRightHanded ? w * 0.48 : w
                        let chordLabelX = manager.isRightHanded ? w * 0.06 : w * 0.94
                        
                        ForEach(
                            [("SHARP", CGFloat(0.33)), ("FLAT", CGFloat(0.66))],
                            id: \.0
                        ) { label, ratio in
                            Path { path in
                                path.move(to: CGPoint(x: chordStartX, y: h * ratio))
                                path.addLine(to: CGPoint(x: chordEndX, y: h * ratio))
                            }
                            .stroke(
                                Color("PrimaryBrown").opacity(0.65),
                                style: StrokeStyle(lineWidth: 1, dash: [7, 5])
                            )
                            
                            Text(label)
                                .font(.custom("Inter", size: 9))
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Color.black.opacity(0.58))
                                .clipShape(Capsule())
                                .position(x: chordLabelX, y: h * ratio - 11)
                        }
                        
                        if let cHand = manager.chordHand {
                            drawHandSkeleton(cHand, width: w, height: h, color: .primaryBrown)
                        }
                        
                        if let sHand = manager.strumHand {
                            drawHandSkeleton(sHand, width: w, height: h, color: .secondaryFont)
                        }
                        
                        let startX = manager.isRightHanded ? w * 0.52 : w * 0.05
                        let endX = manager.isRightHanded ? w * 0.95 : w * 0.48
                        let activeVoicing = manager.activeChord.voicing(for: manager.activeStrumType)

                        ForEach(0..<6) { i in
                            let stringY = stringYPositions[i] * h
                            let vibration = stringVibrations[i]
                            let isDragging = draggingString == i

                            Path { path in
                                path.move(to: CGPoint(x: startX, y: stringY))
                                path.addQuadCurve(
                                    to: CGPoint(x: endX, y: stringY),
                                    control: CGPoint(x: (startX + endX) / 2, y: stringY + vibration)
                                )
                            }
                            .stroke(
                                isDragging ? Color.yellow.opacity(0.9) :
                                    (lastTriggeredStrings[i] ? Color("PrimaryBrown") : Color.white.opacity(0.6)),
                                lineWidth: isDragging ? 3.0 : (lastTriggeredStrings[i] ? 4.0 : 1.5)
                            )
                            .shadow(color: isDragging ? .yellow : (lastTriggeredStrings[i] ? .primaryBrown : .clear), radius: 8)

                            let textX = manager.isRightHanded ? w * 0.54 : w * 0.42
                            let noteLabel = activeVoicing[i]
                            if !noteLabel.isEmpty {
                                Text(noteLabel)
                                    .font(.custom("Playfair Display", size: 9))
                                    .fontWeight(.bold)
                                    .fontDesign(.rounded)
                                    .foregroundColor(Color("PrimaryFont"))
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 1)
                                    .background(lastTriggeredStrings[i] ? Color("PrimaryFont") : Color.black.opacity(0.5))
                                    .cornerRadius(3)
                                    .position(x: textX, y: stringY - 8)
                            }

                            Rectangle()
                                .fill(Color.clear)
                                .contentShape(Rectangle())
                                .frame(width: endX - startX, height: 28)
                                .position(x: (startX + endX) / 2, y: stringY)
                                .gesture(
                                    DragGesture(minimumDistance: 2)
                                        .onChanged { value in
                                            if draggingString != i {
                                                dragStartPositions = stringYPositions
                                                draggingString = i
                                            }
                                            let rawDelta = value.translation.height / h
                                            let minDelta = dragStartPositions.map { 0.18 - $0 }.max()!
                                            let maxDelta = dragStartPositions.map { 0.88 - $0 }.min()!
                                            let clampedDelta = min(max(rawDelta, minDelta), maxDelta)
                                            let newPositions = dragStartPositions.map { $0 + clampedDelta }
                                            stringYPositions = newPositions
                                            manager.stringYPositions = newPositions
                                        }
                                        .onEnded { _ in
                                            draggingString = nil
                                        }
                                )
                        }
                    }
                    VStack {
                        if manager.handScalePercent != nil || manager.handDistanceWarning != nil {
                            handReadabilityIndicator
                                .padding(.top, 54)
                        }
                        Spacer()
                    }
                    VStack {
                        Spacer()
                        HStack(alignment: .bottom, spacing: 20) {
                            if manager.isRightHanded {
                                chordSummaryCard
                                Spacer(minLength: 24)
                                strumPatternCard
                            } else {
                                strumPatternCard
                                Spacer(minLength: 24)
                                chordSummaryCard
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 58)
                    }
                    VStack {
                        Spacer()
                        HStack {
                            Circle()
                                .fill(manager.chordHand != nil ? Color.green : Color.red)
                                .frame(width: 6, height: 6)
                            Text(manager.statusMessage)
                                .font(.custom("Playfair Display", size: 15))
                                .fontDesign(.monospaced)
                                .foregroundColor(Color("PrimaryFont"))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color("PrimaryDark").opacity(0.7))
                        .clipShape(Capsule())
                        .padding(.bottom, 12)
                    }
                }
                .onReceive(manager.stringPluckedSubject) { stringIndex in
                    triggerStrumAction(for: stringIndex)
                }
            } else {
                PermissionRequestView(manager: manager)
            }
        }
    }
    
    private var chordSummaryCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("CHORD DETECTED")
                .font(.custom("Inter", size: 11))
                .fontWeight(.bold)
                .tracking(1.4)
                .foregroundStyle(cardSecondaryForeground)
            
            HStack(alignment: .firstTextBaseline, spacing: 7) {
                Text(manager.activeChord.rawValue + manager.activeAccidental.suffix)
                    .font(.custom("Playfair Display", size: 48))
                    .fontWeight(.black)
                
                Text(manager.activeStrumType == .none ? "—" : manager.activeStrumType.rawValue)
                    .font(.custom("Playfair Display", size: 28))
                    .fontWeight(.bold)
            }
            .foregroundStyle(cardForeground)
            
            Label(accidentalTitle, systemImage: accidentalIcon)
                .font(.custom("Inter", size: 11))
                .fontWeight(.semibold)
                .foregroundStyle(accidentalColor)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(accidentalColor.opacity(0.16))
                .clipShape(Capsule())
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .frame(width: 300, height: 126, alignment: .leading)
        .background(panelBackground.opacity(0.88))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color("PrimaryBrown").opacity(0.65), lineWidth: 1)
        }
    }
    
    private var handReadabilityIndicator: some View {
        HStack(spacing: 8) {
            Image(systemName: handReadabilityIsIdeal ? "checkmark.circle.fill" : "viewfinder.circle")

            VStack(alignment: .leading, spacing: 1) {
                Text(handReadabilityTitle)
                    .font(.custom("Inter", size: 11))
                    .fontWeight(.bold)

                Text("Readable 18–72% • ideal 25–60% of frame")
                    .font(.custom("Inter", size: 9))
                    .opacity(0.78)
            }
        }
        .foregroundStyle(handReadabilityColor)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.68))
        .clipShape(Capsule())
        .overlay {
            Capsule().stroke(handReadabilityColor.opacity(0.65), lineWidth: 1)
        }
    }
    
    private var strumPatternCard: some View {
        VStack(alignment: .trailing, spacing: 7) {
            Text("STRUMMING PATTERN")
                .font(.custom("Inter", size: 11))
                .fontWeight(.bold)
                .tracking(1.2)
                .foregroundStyle(cardSecondaryForeground)

            HStack(spacing: 8) {
                Image(systemName: manager.isStrumTypeLocked ? "lock.fill" : "hand.raised.fill")
                Text(manager.activeStrumType.rawValue)
                    .font(.custom("Playfair Display", size: 30))
                    .fontWeight(.bold)
            }
            .foregroundStyle(manager.isStrumTypeLocked ? Color.green : cardForeground)

            Text(manager.isStrumTypeLocked
                 ? "LOCKED • turn the back of your hand to camera, then pinch to pick"
                 : "Show Maj, Min7, Min, or Maj7")
                .font(.custom("Inter", size: 10))
                .foregroundStyle(cardSecondaryForeground)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 270, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .frame(width: 300, height: 126, alignment: .trailing)
        .background(panelBackground.opacity(0.88))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    manager.isStrumTypeLocked ? Color.green.opacity(0.7) : Color.white.opacity(0.18),
                    lineWidth: 1
                )
        }
    }
    
    private func triggerStrumAction(for stringIndex: Int) {
        guard manager.activeStrumType != .none,
              stringIndex >= 0,
              stringIndex < 6 else { return }

        let voicing = manager.activeChord.voicing(for: manager.activeStrumType)
        let noteName = voicing[stringIndex]
        if !noteName.isEmpty {
            chordPlayer.playNote(noteName)
        }

        withAnimation(.interactiveSpring(response: 0.12, dampingFraction: 0.12)) {
            stringVibrations[stringIndex] = 14
            lastTriggeredStrings[stringIndex] = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.04) {
            withAnimation(.interactiveSpring(response: 0.22, dampingFraction: 0.18)) {
                stringVibrations[stringIndex] = 0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            lastTriggeredStrings[stringIndex] = false
        }
    }
    
    private var handReadabilityIsIdeal: Bool {
        guard let scale = manager.handScalePercent else { return false }
        return manager.handDistanceWarning == nil && (25...60).contains(scale)
    }

    private var handReadabilityTitle: String {
        let percentage = manager.handScalePercent.map { " • \($0)%" } ?? ""
        if let warning = manager.handDistanceWarning {
            return warning + percentage
        }
        if handReadabilityIsIdeal {
            return "VISION READY" + percentage
        }
        return "READABLE • ADJUST TO IDEAL RANGE" + percentage
    }

    private var handReadabilityColor: Color {
        if manager.handDistanceWarning != nil { return .orange }
        return handReadabilityIsIdeal ? .green : .yellow
    }

    

    private var accidentalTitle: String {
        switch manager.activeAccidental {
        case .sharp: return "SHARP"
        case .natural: return "NORMAL"
        case .flat: return "FLAT"
        }
    }

    private var accidentalIcon: String {
        switch manager.activeAccidental {
        case .sharp: return "number"
        case .natural: return "music.note"
        case .flat: return "music.note"
        }
    }

    private var accidentalColor: Color {
        switch manager.activeAccidental {
        case .sharp: return .orange
        case .natural: return Color("SecondaryFont")
        case .flat: return .blue
        }
    }
    
    private var panelBackground: Color {
        colorScheme == .dark ? .black : .white
    }

    private var cardForeground: Color {
        colorScheme == .dark ? .white : .black
    }

    private var cardSecondaryForeground: Color {
        cardForeground.opacity(0.68)
    }
}

#Preview {
    HandTrackingExperienceView(manager: HandPoseManager(), chordPlayer: ChordPlayer())
}
