import SwiftUI
import Vision

struct ContentView: View {
    @StateObject private var manager = HandPoseManager()
    @StateObject private var chordPlayer = ChordPlayer()

    private let bgGradient = LinearGradient(
        colors: [Color(red: 0.05, green: 0.05, blue: 0.1), Color(red: 0.1, green: 0.1, blue: 0.2)],
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
                        cameraContainerView
                        chordDisplayView
                    }
                    .padding()
                }
            } else {
                permissionView
            }
        }
        .onAppear { manager.checkPermissionAndStart() }
        .onDisappear { manager.stopSession() }
        .onChange(of: manager.detectedHands.first?.chord) { _, chord in
            guard let chord, chord != .none else { return }
            chordPlayer.playChord(chord.notes)
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Hand Chord Recognition")
                    .font(.system(.title, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                Text("Musical chords via hand signs")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.6))
            }

            Spacer()

            Button(action: { manager.toggleCamera() }) {
                Image(systemName: "camera.rotate.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Camera Container (9:16)

    private var cameraContainerView: some View {
        ZStack {
            CameraPreviewView(session: manager.session)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [.cyan.opacity(0.5), .purple.opacity(0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )

            GeometryReader { geo in
                let w = geo.size.width, h = geo.size.height
                ForEach(manager.detectedHands) { hand in
                    Path { path in
                        for line in hand.skeletonLines {
                            guard let first = line.first else { continue }
                            path.move(to: CGPoint(x: first.x * w, y: first.y * h))
                            for pt in line.dropFirst() {
                                path.addLine(to: CGPoint(x: pt.x * w, y: pt.y * h))
                            }
                        }
                    }
                    .stroke(Color.cyan.opacity(0.7), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

                    ForEach(Array(hand.joints.values)) { joint in
                        Circle()
                            .fill(Color.cyan)
                            .frame(width: 8, height: 8)
                            .shadow(color: .cyan, radius: 4)
                            .position(x: joint.location.x * w, y: joint.location.y * h)
                    }
                }
            }

            VStack {
                Spacer()
                HStack {
                    Image(systemName: "info.circle.fill").foregroundColor(.cyan)
                    Text(manager.statusMessage)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.6))
                .clipShape(Capsule())
                .padding(.bottom, 16)
            }
        }
        .aspectRatio(9.0 / 16.0, contentMode: .fit)
        .background(Color.black.opacity(0.3))
        .cornerRadius(24)
    }

    // MARK: - Chord Display

    private var chordDisplayView: some View {
        Group {
            if let hand = manager.detectedHands.first {
                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(hand.chord != .none ? Color.cyan.opacity(0.15) : Color.white.opacity(0.05))
                            .frame(width: 72, height: 72)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        hand.chord != .none ? Color.cyan.opacity(0.4) : Color.white.opacity(0.1),
                                        lineWidth: 1
                                    )
                            )

                        Text(hand.chord.rawValue)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(hand.chord != .none ? .cyan : .white.opacity(0.4))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(hand.chord != .none ? "Chord Detected" : "No Chord")
                            .font(.headline)
                            .foregroundColor(hand.chord != .none ? .cyan : .white)

                        Text(hand.chord.fingerPattern)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))

                        Text(hand.isLeftHand ? "Left Hand" : "Right Hand")
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundColor(.white.opacity(0.4))
                    }

                    Spacer()

                    Text(String(format: "%.0f%%", hand.confidence * 100))
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.white.opacity(0.4))
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 18))
            } else {
                HStack {
                    Image(systemName: "hand.raised.slash.fill")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.3))

                    Text("No hand detected. Show your hand to the camera.")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.leading, 8)

                    Spacer()
                }
                .padding()
                .background(Color.white.opacity(0.02))
                .clipShape(RoundedRectangle(cornerRadius: 18))
            }
        }
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

                Text("This app uses Vision to detect hand poses and recognize musical chord signs.")
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
