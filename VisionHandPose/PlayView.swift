import SwiftUI
import Vision
import Combine

struct PlayView: View {
    @ObservedObject var manager: HandPoseManager
    @ObservedObject var chordPlayer: ChordPlayer
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @State private var stringVibrations: [CGFloat] = [0, 0, 0, 0, 0, 0]
    @State private var lastTriggeredStrings: [Bool] = [false, false, false, false, false, false]
    @State private var showTutorial = true
    @State private var isLandscape = false
    
    var body: some View {
        NavigationStack {
            Group {
                if manager.cameraPermissionGranted {
                    if isLandscape {
                        // iPad Side-by-Side Split Layout
                        HStack(spacing: 24) {
                            cameraSection
                                .frame(maxWidth: .infinity)
                            
                            ScrollView {
                                VStack(spacing: 20) {
                                    activeChordCard
                                    
                                    strumControlCard
                                    
                                    if showTutorial {
                                        tutorialGuideCard
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.vertical)
                            }
                            .frame(width: 290)
                        }
                        .padding(.horizontal, 24)
                    } else {
                        // iPhone Vertical Stack Layout
                        ScrollView {
                            VStack(spacing: 20) {
                                cameraSection
                                
                                activeChordCard
                                
                                strumControlCard
                                
                                if showTutorial {
                                    tutorialGuideCard
                                }
                            }
                            .padding()
                        }
                    }
                } else {
                    PermissionRequestView(manager: manager)
                }
            }
            .navigationTitle("Air Guitar Play")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Left Toolbar: Handedness
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { manager.isRightHanded.toggle() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "hand.raised.fill")
                            Text(manager.isRightHanded ? "Right-Handed" : "Left-Handed")
                        }
                        .font(.footnote)
                    }
                }
                
                // Right Toolbar: Camera Rotation & Tutorial toggles
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        Button(action: {
                            withAnimation { showTutorial.toggle() }
                        }) {
                            Image(systemName: showTutorial ? "info.circle.fill" : "info.circle")
                        }
                        
                        Button(action: { manager.toggleCamera() }) {
                            Image(systemName: "camera.rotate.fill")
                        }
                    }
                }
            }
            .onAppear {
                forceLandscape()
                updateOrientation()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                updateOrientation()
                manager.updateVideoOrientation()
            }
            .onReceive(manager.stringPluckedSubject) { stringIndex in
                triggerStrumAction(for: stringIndex)
            }
        }
    }
    
    // MARK: - Action Trigger
    
    
    
    private func strumAll() {
        for i in 0..<6 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.045) {
                triggerStrumAction(for: i)
            }
        }
    }
    
    // MARK: - Camera & Overlay Section
    
    private var cameraSection: some View {
        ZStack {
            CameraPreviewView(session: manager.session)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [.purple.opacity(0.3), .green.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
            
            // Vision Overlays
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                
                // Central Laser partition
                Path { path in
                    path.move(to: CGPoint(x: w * 0.5, y: 0))
                    path.addLine(to: CGPoint(x: w * 0.5, y: h))
                }
                .stroke(
                    LinearGradient(
                        colors: [.purple.opacity(0.1), .cyan.opacity(0.5), .purple.opacity(0.1)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    style: StrokeStyle(lineWidth: 1.5, dash: [8, 4])
                )
                
                // Zone Labels
                ZoneLabel(
                    title: manager.isRightHanded ? "CHORD ZONE (FRET)" : "STRUM ZONE (STRINGS)",
                    color: manager.isRightHanded ? Color.purple : Color.green,
                    x: w * 0.25,
                    y: 28
                )

                ZoneLabel(
                    title: manager.isRightHanded ? "STRUM ZONE (STRINGS)" : "CHORD ZONE (FRET)",
                    color: manager.isRightHanded ? Color.green : Color.purple,
                    x: w * 0.75,
                    y: 28
                )

                // Accidental zone indicators (horizontal lines)
                if manager.isRightHanded {
                    // Sharp zone line (top third)
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: h * 0.33))
                        path.addLine(to: CGPoint(x: w * 0.48, y: h * 0.33))
                    }
                    .stroke(
                        LinearGradient(
                            colors: [.orange, .orange.opacity(0.6)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 2, dash: [6, 4])
                    )

                    // Natural zone line (middle)
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: h * 0.66))
                        path.addLine(to: CGPoint(x: w * 0.48, y: h * 0.66))
                    }
                    .stroke(
                        LinearGradient(
                            colors: [.green, .green.opacity(0.6)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 2, dash: [6, 4])
                    )

                    // Accidental labels
                    Text("♯ SHARP")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.orange)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Capsule())
                        .position(x: w * 0.44, y: h * 0.33)

                    Text("♭ FLAT")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.blue)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Capsule())
                        .position(x: w * 0.44, y: h * 0.66)
                }
                
                // Skeletons
                if let cHand = manager.chordHand {
                    drawHandSkeleton(cHand, width: w, height: h, color: .purple)
                }

                if let sHand = manager.strumHand {
                    drawHandSkeleton(sHand, width: w, height: h, color: .green)
                }

                // Finger distance gauges in chord zone (left side)
                if let cHand = manager.chordHand, manager.isRightHanded {
                    FingerDistanceGauges(fingerDistances: cHand.fingerDistances)
                        .frame(width: w * 0.48, height: h)
                        .position(x: w * 0.24, y: h * 0.5)
                }
                
                // 6 horizontal strings
                let startX = manager.isRightHanded ? w * 0.52 : w * 0.05
                let endX = manager.isRightHanded ? w * 0.95 : w * 0.48
                let stringYPositions: [CGFloat] = [0.35, 0.41, 0.47, 0.53, 0.59, 0.65]
                
                ForEach(0..<6) { i in
                    let stringY = stringYPositions[i] * h
                    let vibration = stringVibrations[i]
                    
                    Path { path in
                        path.move(to: CGPoint(x: startX, y: stringY))
                        path.addQuadCurve(
                            to: CGPoint(x: endX, y: stringY),
                            control: CGPoint(x: (startX + endX) / 2, y: stringY + vibration)
                        )
                    }
                    .stroke(
                        lastTriggeredStrings[i] ? Color.green : Color.white.opacity(0.6),
                        lineWidth: lastTriggeredStrings[i] ? 4.0 : 1.5
                    )
                    .shadow(color: lastTriggeredStrings[i] ? .green : .clear, radius: 8)
                    
                    // Hovering Note indicator
                    let textX = manager.isRightHanded ? w * 0.54 : w * 0.42
                    let noteLabel = manager.activeChord.guitarStrings[i]
                    if !noteLabel.isEmpty {
                        Text(noteLabel)
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(lastTriggeredStrings[i] ? Color.green : Color.black.opacity(0.5))
                            .cornerRadius(3)
                            .position(x: textX, y: stringY - 8)
                    }
                }
            }
            
            // Bottom Status Message
            VStack {
                Spacer()
                HStack {
                    Circle()
                        .fill(manager.chordHand != nil ? Color.green : Color.cyan)
                        .frame(width: 6, height: 6)
                    Text(manager.statusMessage)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.7))
                .clipShape(Capsule())
                .padding(.bottom, 12)
            }
        }
        .aspectRatio(isLandscape ? 16.0 / 9.0 : 9.0 / 16.0, contentMode: .fit)
        .background(Color.black.opacity(0.2))
        .cornerRadius(24)
    }
    
        
    // MARK: - Subcards
    
    private var activeChordCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ACTIVE CHORD")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.5))

                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(manager.activeChord.rawValue)
                            .font(.system(size: 40, weight: .black, design: .rounded))
                            .foregroundColor(manager.activeChord != .none ? .cyan : .white.opacity(0.3))

                        if manager.activeChord != .none {
                            Text(manager.activeAccidental.suffix)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(manager.activeAccidental == .sharp ? .orange :
                                                manager.activeAccidental == .flat ? .blue : .cyan)
                        }
                    }

                    // Strum chord type indicator
                    if manager.strumHand != nil {
                        Text(manager.activeStrumType.rawValue)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.green)
                    }
                }

                Spacer()

                // Strum shortcut
                Button(action: strumAll) {
                    Image(systemName: "music.note.list")
                        .font(.title2)
                        .foregroundColor(.black)
                        .padding(14)
                        .background(manager.activeChord != .none ? Color.cyan : Color.white.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(manager.activeChord == .none)
            }

            if manager.activeChord != .none {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.cyan)
                        Text(manager.activeChord.fingerPattern)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }

                    Text("Voicing: " + manager.activeChord.guitarStrings.filter({ !$0.isEmpty }).joined(separator: " - "))
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.white.opacity(0.5))

                    // Strum type finger pattern
                    if manager.strumHand != nil {
                        HStack {
                            Image(systemName: "hand.point.up.fill")
                                .foregroundColor(.green)
                            Text(manager.activeStrumType.fingerPattern)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 4)
            }
        }
        .padding(18)
        .background(Color.white.opacity(0.06))
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
    
    private var strumControlCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("String Strum Dashboard")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white.opacity(0.6))
            
            VStack(spacing: 8) {
                let strings = ["6th String (E3)", "5th String (A3)", "4th String (D4)", "3rd String (G4)", "2nd String (B4)", "1st String (E5)"]
                
                ForEach(0..<6) { i in
                    let note = manager.activeChord.guitarStrings[i]
                    
                    Button(action: { triggerStrumAction(for: i) }) {
                        HStack {
                            Circle()
                                .fill(lastTriggeredStrings[i] ? Color.green : Color.white.opacity(0.2))
                                .frame(width: 8, height: 8)
                            
                            Text(strings[i])
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                            
                            Spacer()
                            
                            if !note.isEmpty {
                                Text(note)
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(lastTriggeredStrings[i] ? Color.green : Color.cyan)
                                    .cornerRadius(4)
                            } else {
                                Text("—")
                                    .foregroundColor(.white.opacity(0.3))
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(lastTriggeredStrings[i] ? Color.green.opacity(0.1) : Color.white.opacity(0.04))
                        .cornerRadius(10)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(18)
    }
    
    private var tutorialGuideCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Quick Play Guide")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.cyan)
                
                Spacer()
                
                Button(action: { withAnimation { showTutorial = false } }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.4))
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                TutorialRow(step: "1", text: "Place both hands in camera view.")
                TutorialRow(step: "2", text: "Hold up hand shapes in Purple zone to set chord.")
                TutorialRow(step: "3", text: "Sweep index finger vertically in Green zone to strum strings.")
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.04))
        .cornerRadius(18)
    }
    
}

// MARK: - Helper Views

private struct ZoneLabel: View {
    let title: String
    let color: Color
    let x: CGFloat
    let y: CGFloat

    var body: some View {
        Text(title)
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.5))
            .clipShape(Capsule())
            .position(x: x, y: y)
    }
}

private struct TutorialRow: View {
    let step: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(step)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(.black)
                .frame(width: 22, height: 22)
                .background(Color.cyan)
                .clipShape(Circle())
            Text(text)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct FingerDistanceGauges: View {
    let fingerDistances: [String: CGFloat]
    let threshold: CGFloat = 0.15
    
    private let fingerOrder = ["thumb", "index", "middle", "ring", "little"]
    private let fingerLabels = ["T", "I", "M", "R", "L"]
    
    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 8) {
                ForEach(0..<5) { i in
                    let finger = fingerOrder[i]
                    let distance = fingerDistances[finger] ?? 0
                    let isExtended = distance > threshold
                    
                    VStack(spacing: 4) {
                        // Finger label
                        Text(fingerLabels[i])
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.6))
                        
                        // Vertical gauge bar
                        ZStack(alignment: .bottom) {
                            // Background track
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.black.opacity(0.4))
                                .frame(width: 16, height: 80)
                            
                            // Fill bar
                            RoundedRectangle(cornerRadius: 4)
                                .fill(isExtended ? Color.green : Color.red)
                                .frame(width: 16, height: min(distance * 200, 80))
                                .animation(.easeOut(duration: 0.1), value: distance)
                            
                            // Threshold line
                            Rectangle()
                                .fill(Color.white.opacity(0.5))
                                .frame(width: 20, height: 2)
                                .offset(y: -threshold * 200 + 80)
                            
                            // Distance value
                            Text(String(format: "%.2f", distance))
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                                .padding(.top, 2)
                        }
                        
                        // Extended/curled status
                        Text(isExtended ? "↑" : "↓")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(isExtended ? .green : .red)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 12)
            .background(Color.black.opacity(0.3))
            .cornerRadius(8)
        }
    }
}

#Preview {
    PlayView(manager: HandPoseManager(), chordPlayer: ChordPlayer())
}
