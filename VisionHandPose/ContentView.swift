import SwiftUI
import Vision
import UIKit
import Combine

struct ContentView: View {
    @StateObject private var manager = HandPoseManager()
    @StateObject private var chordPlayer = ChordPlayer()
    
    // Interactive guitar string vibration offsets
    @State private var stringVibrations: [CGFloat] = [0, 0, 0, 0, 0, 0]
    @State private var lastTriggeredStrings: [Bool] = [false, false, false, false, false, false]
    
    @State private var isLandscape = false
    @State private var showTutorial = true
    
    private let bgGradient = LinearGradient(
        colors: [Color(red: 0.05, green: 0.05, blue: 0.12), Color(red: 0.08, green: 0.08, blue: 0.2)],
        startPoint: .top,
        endPoint: .bottom
    )
    
    var body: some View {
        ZStack {
            bgGradient.ignoresSafeArea()
            
            if manager.cameraPermissionGranted {
                ScrollView {
                    VStack(spacing: 20) {
                        headerView
                        
                        // Main Camera + Guitar Neck Visualizer
                        cameraGuitarView
                        
                        // Chord & Guitar Controls
                        guitarControlsView
                        
                        // Interactive Virtual Fretboard (Play by click/tap)
                        virtualFretboardView
                        
                        if showTutorial {
                            tutorialInstructionsView
                        }
                    }
                    .padding()
                }
            } else {
                permissionView
            }
        }
        .onAppear {
            updateInterfaceOrientation()
            manager.checkPermissionAndStart()
        }
        .onDisappear {
            chordPlayer.stopAllNotes()
            manager.stopSession()
        }
        // Listen to strum events from HandPoseManager
        .onReceive(manager.stringPluckedSubject) { stringIndex in
            triggerStrumAction(for: stringIndex)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            updateInterfaceOrientation()
            manager.updateVideoOrientation()
        }
    }
    
    // MARK: - Action Trigger
    
    private func triggerStrumAction(for stringIndex: Int) {
        let chord = manager.activeChord
        guard stringIndex >= 0 && stringIndex < 6 else { return }
        
        // 1. Play synthesized note
        let noteName = chord.guitarStrings[stringIndex]
        if !noteName.isEmpty {
            chordPlayer.playNote(noteName)
        }
        
        // 2. Animate string vibration
        withAnimation(.interactiveSpring(response: 0.12, dampingFraction: 0.12, blendDuration: 0)) {
            stringVibrations[stringIndex] = 14
            lastTriggeredStrings[stringIndex] = true
        }
        
        // Reset vibration using a spring overshoot to create wobble
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.04) {
            withAnimation(.interactiveSpring(response: 0.22, dampingFraction: 0.18, blendDuration: 0)) {
                stringVibrations[stringIndex] = 0
            }
        }
        
        // Turn off green trigger indicator after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            lastTriggeredStrings[stringIndex] = false
        }
    }
    
    private func strumAll() {
        let chord = manager.activeChord
        
        // Pluck each string sequentially with a 45ms delay for realistic strumming arpeggio
        for i in 0..<6 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.045) {
                triggerStrumAction(for: i)
            }
        }
    }
    
    private func updateInterfaceOrientation() {
        let orientation = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?
            .interfaceOrientation
        
        isLandscape = orientation?.isLandscape == true
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Vision Virtual Guitar")
                    .font(.system(.title, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                
                Text("Left Hand = Chord, Right Hand = Strum")
                    .font(.footnote)
                    .foregroundStyle(.cyan.opacity(0.8))
            }
            
            Spacer()
            
            // Camera toggle
            Button(action: { manager.toggleCamera() }) {
                Image(systemName: "camera.rotate.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.white.opacity(0.12))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 4)
    }
    
    // MARK: - Camera & Guitar View
    
    private var cameraGuitarView: some View {
        ZStack {
            // Live camera view
            CameraPreviewView(session: manager.session)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [.purple.opacity(0.4), .green.opacity(0.4)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                )
                .shadow(color: .purple.opacity(0.15), radius: 10)
            
            // Guitar Overlays & Hand Tracking
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                
                // 1. Draw central partition laser
                Path { path in
                    path.move(to: CGPoint(x: w * 0.5, y: 0))
                    path.addLine(to: CGPoint(x: w * 0.5, y: h))
                }
                .stroke(
                    LinearGradient(
                        colors: [.purple.opacity(0.1), .cyan.opacity(0.6), .purple.opacity(0.1)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                )
                
                // 2. Draw active zone indicators
                ZoneLabel(
                    title: manager.isRightHanded ? "CHORD ZONE (FRETBOARD)" : "STRUM ZONE (STRINGS)",
                    color: manager.isRightHanded ? .purple : .green,
                    x: w * 0.25,
                    y: 28
                )
                
                ZoneLabel(
                    title: manager.isRightHanded ? "STRUM ZONE (STRINGS)" : "CHORD ZONE (FRETBOARD)",
                    color: manager.isRightHanded ? .green : .purple,
                    x: w * 0.75,
                    y: 28
                )
                
                // 3. Draw Skeletons
                if let cHand = manager.chordHand {
                    drawHandSkeleton(cHand, width: w, height: h, color: .purple)
                }
                
                if let sHand = manager.strumHand {
                    drawHandSkeleton(sHand, width: w, height: h, color: .green)
                }
                
                // 4. Draw 6 virtual horizontal strings
                let startX = manager.isRightHanded ? w * 0.52 : w * 0.05
                let endX = manager.isRightHanded ? w * 0.95 : w * 0.48
                let stringYPositions: [CGFloat] = [0.35, 0.41, 0.47, 0.53, 0.59, 0.65]
                
                ForEach(0..<6) { i in
                    let stringY = stringYPositions[i] * h
                    let vibration = stringVibrations[i]
                    
                    Path { path in
                        path.move(to: CGPoint(x: startX, y: stringY))
                        // Add a curve in the center to represent plucked vibration
                        path.addQuadCurve(
                            to: CGPoint(x: endX, y: stringY),
                            control: CGPoint(x: (startX + endX) / 2, y: stringY + vibration)
                        )
                    }
                    .stroke(
                        lastTriggeredStrings[i] ? Color.green : Color.white.opacity(0.65),
                        lineWidth: lastTriggeredStrings[i] ? 4.5 : 2.0
                    )
                    .shadow(color: lastTriggeredStrings[i] ? .green : .clear, radius: 8)
                    
                    // Note label hovering near the string
                    let textX = manager.isRightHanded ? w * 0.54 : w * 0.42
                    let noteLabel = manager.activeChord.guitarStrings[i]
                    if !noteLabel.isEmpty {
                        Text(noteLabel)
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(lastTriggeredStrings[i] ? Color.green : Color.black.opacity(0.5))
                            .cornerRadius(3)
                            .position(x: textX, y: stringY - 8)
                    }
                }
            }
            
            // Bottom Status Message Overlay
            VStack {
                Spacer()
                HStack {
                    Circle()
                        .fill(manager.chordHand != nil ? Color.green : Color.cyan)
                        .frame(width: 8, height: 8)
                    Text(manager.statusMessage)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.65))
                .clipShape(Capsule())
                .padding(.bottom, 16)
            }
        }
        .aspectRatio(isLandscape ? 16.0 / 9.0 : 9.0 / 16.0, contentMode: .fit)
        .background(Color.black.opacity(0.3))
        .cornerRadius(24)
    }
    
    // MARK: - Hand Drawing Helper
    
    private func drawHandSkeleton(_ hand: HandPose, width: CGFloat, height: CGFloat, color: Color) -> some View {
        Group {
            // Bones
            Path { path in
                for line in hand.skeletonLines {
                    guard let first = line.first else { continue }
                    path.move(to: CGPoint(x: first.x * width, y: first.y * height))
                    for pt in line.dropFirst() {
                        path.addLine(to: CGPoint(x: pt.x * width, y: pt.y * height))
                    }
                }
            }
            .stroke(color.opacity(0.75), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
            
            // Joint Points
            ForEach(Array(hand.joints.values)) { joint in
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                    .shadow(color: color, radius: 4)
                    .position(x: joint.location.x * width, y: joint.location.y * height)
            }
        }
    }
    
    // MARK: - Controls Panel
    
    private var guitarControlsView: some View {
        VStack(spacing: 16) {
            // Chord Display & Strum All Button
            HStack(spacing: 16) {
                // Chord Badge
                VStack(alignment: .leading, spacing: 4) {
                    Text("ACTIVE CHORD")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.5))
                    
                    Text(manager.activeChord.rawValue)
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundColor(manager.activeChord != .none ? .cyan : .white.opacity(0.3))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.06))
                .cornerRadius(18)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(manager.activeChord != .none ? Color.cyan.opacity(0.3) : Color.white.opacity(0.08), lineWidth: 1)
                )
                
                // Strum Button
                Button(action: strumAll) {
                    HStack {
                        Image(systemName: "music.note.list")
                            .font(.title2)
                        Text("STRUM CHORD")
                            .font(.system(.subheadline, design: .rounded))
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.vertical, 18)
                    .background(manager.activeChord != .none ? Color.cyan : Color.white.opacity(0.12))
                    .cornerRadius(18)
                    .shadow(color: manager.activeChord != .none ? Color.cyan.opacity(0.3) : Color.clear, radius: 8)
                }
                .disabled(manager.activeChord == .none)
            }
            
            // Handedness and Tutorial Toggles
            HStack(spacing: 12) {
                // Handedness Toggle
                Button(action: {
                    manager.isRightHanded.toggle()
                }) {
                    HStack {
                        Image(systemName: "hand.raised.fill")
                        Text(manager.isRightHanded ? "Right-Handed Mode" : "Left-Handed Mode")
                            .fontWeight(.medium)
                    }
                    .font(.footnote)
                    .foregroundColor(.white)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(12)
                }
                
                // Instructions Toggle
                Button(action: {
                    withAnimation {
                        showTutorial.toggle()
                    }
                }) {
                    HStack {
                        Image(systemName: "questionmark.circle.fill")
                        Text(showTutorial ? "Hide Help" : "Show Help")
                            .fontWeight(.medium)
                    }
                    .font(.footnote)
                    .foregroundColor(.white)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(12)
                }
            }
        }
    }
    
    // MARK: - Interactive Virtual Fretboard
    
    private var virtualFretboardView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Virtual Fretboard strings (Tap to pluck)")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white.opacity(0.6))
                .padding(.horizontal, 4)
            
            VStack(spacing: 8) {
                let stringNames = ["6th String (Low E)", "5th String (A)", "4th String (D)", "3rd String (G)", "2nd String (B)", "1st String (High E)"]
                
                ForEach(0..<6) { i in
                    let note = manager.activeChord.guitarStrings[i]
                    
                    Button(action: {
                        triggerStrumAction(for: i)
                    }) {
                        HStack {
                            Text(stringNames[i])
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                            
                            Spacer()
                            
                            if !note.isEmpty {
                                Text(note)
                                    .font(.system(.subheadline, design: .monospaced))
                                    .fontWeight(.bold)
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(lastTriggeredStrings[i] ? Color.green : Color.cyan)
                                    .cornerRadius(6)
                            } else {
                                Text("—")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.3))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(lastTriggeredStrings[i] ? Color.green.opacity(0.12) : Color.white.opacity(0.04))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(lastTriggeredStrings[i] ? Color.green.opacity(0.4) : Color.clear, lineWidth: 1)
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Tutorial View
    
    private var tutorialInstructionsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How to Play the Virtual Air Guitar")
                .font(.headline)
                .foregroundColor(.cyan)
            
            VStack(alignment: .leading, spacing: 8) {
                TutorialRow(step: "1", text: "Posisikan tangan Anda di depan kamera (jarak ideal 1 - 2 meter).")
                TutorialRow(step: "2", text: "Gunakan tangan KIRI Anda di sisi kiri layar untuk membentuk Kunci/Chord (misal: acungkan jempol untuk nada A, acungkan telunjuk untuk nada C).")
                TutorialRow(step: "3", text: "Gunakan tangan KANAN Anda di sisi kanan layar untuk memetik gitar (gerakkan ujung jari telunjuk ke atas/bawah melewati 6 garis horizontal).")
                TutorialRow(step: "4", text: "Setiap kali jari telunjuk memotong garis senar, ia akan memicu suara petikan gitar akustik yang disintesis secara real-time!")
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
    
    // MARK: - Permission View
    
    private var permissionView: some View {
        VStack(spacing: 24) {
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 64))
                .foregroundColor(.cyan)
                .shadow(color: .cyan.opacity(0.4), radius: 10)
            
            VStack(spacing: 8) {
                Text("Camera Access Required")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("This app uses Vision to track hand gestures for virtual chord changes and strumming.")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Button(action: { manager.checkPermissionAndStart() }) {
                Text("Enable Camera Access")
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(Color.cyan)
                    .cornerRadius(16)
                    .shadow(color: .cyan.opacity(0.3), radius: 8)
            }
        }
        .padding()
    }
}

// MARK: - Subcomponents

struct ZoneLabel: View {
    let title: String
    let color: Color
    let x: CGFloat
    let y: CGFloat
    
    var body: some View {
        Text(title)
            .font(.system(size: 9, weight: .bold, design: .monospaced))
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .cornerRadius(4)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(color.opacity(0.25), lineWidth: 1)
            )
            .position(x: x, y: y)
    }
}

struct TutorialRow: View {
    let step: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(step)
                .font(.system(.caption, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(.black)
                .frame(width: 18, height: 18)
                .background(Color.cyan)
                .clipShape(Circle())
                .padding(.top, 2)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .lineSpacing(3)
        }
    }
}
