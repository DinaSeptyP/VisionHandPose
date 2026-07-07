import SwiftUI
import Vision

struct ContentView: View {
    @StateObject private var manager = HandPoseManager()
    @State private var showingInfoSheet = false
    
    // UI Theme colors
    private let bgGradient = LinearGradient(
        colors: [Color(red: 0.05, green: 0.05, blue: 0.1), Color(red: 0.1, green: 0.1, blue: 0.2)],
        startPoint: .top,
        endPoint: .bottom
    )
    
    var body: some View {
        ZStack {
            // Background
            bgGradient
                .ignoresSafeArea()
            
            if manager.cameraPermissionGranted {
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        headerView
                        
                        // Live Camera View with Skeleton Overlay
                        cameraContainerView
                        
                        // Dashboard of Detected Gestures
                        gestureDashboardView
                        
                        // Real-Time Distance Analytics
                        distanceAnalyticsView
                        
                        // Footer & Info Button
                        infoButton
                    }
                    .padding()
                }
            } else {
                permissionView
            }
        }
        .onAppear {
            manager.checkPermissionAndStart()
        }
        .onDisappear {
            manager.stopSession()
        }
        .sheet(isPresented: $showingInfoSheet) {
            VisionAnalysisSheet()
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Vision Hand Pose")
                    .font(.system(.title, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                
                Text("Pure Apple Vision API Tracking")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.6))
            }
            
            Spacer()
            
            // Camera Switch Button
            Button(action: {
                manager.toggleCamera()
            }) {
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
    
    // MARK: - Camera Container View (9:16 Aspect Ratio)
    
    private var cameraContainerView: some View {
        VStack(spacing: 0) {
            ZStack {
                // Live camera preview
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
                
                // Skeleton Overlay
                GeometryReader { geometry in
                    let width = geometry.size.width
                    let height = geometry.size.height
                    
                    // Draw connections & joints
                    ForEach(manager.detectedHands) { hand in
                        // Draw skeleton lines
                        Path { path in
                            for line in hand.skeletonLines {
                                if let firstPoint = line.first {
                                    path.move(to: CGPoint(x: firstPoint.x * width, y: firstPoint.y * height))
                                    for point in line.dropFirst() {
                                        path.addLine(to: CGPoint(x: point.x * width, y: point.y * height))
                                    }
                                }
                            }
                        }
                        .stroke(
                            Color.cyan.opacity(0.7),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                        )
                        
                        // Highlight active pinch line (if pinching)
                        if let indexTip = hand.joints[.indexTip],
                           let thumbTip = hand.joints[.thumbTip],
                           hand.gesture == .pinchIndex {
                            Path { path in
                                path.move(to: CGPoint(x: indexTip.location.x * width, y: indexTip.location.y * height))
                                path.addLine(to: CGPoint(x: thumbTip.location.x * width, y: thumbTip.location.y * height))
                            }
                            .stroke(
                                Color.green,
                                style: StrokeStyle(lineWidth: 5, lineCap: .round, dash: [5, 3])
                            )
                        }
                        
                        if let middleTip = hand.joints[.middleTip],
                           let thumbTip = hand.joints[.thumbTip],
                           hand.gesture == .pinchMiddle {
                            Path { path in
                                path.move(to: CGPoint(x: middleTip.location.x * width, y: middleTip.location.y * height))
                                path.addLine(to: CGPoint(x: thumbTip.location.x * width, y: thumbTip.location.y * height))
                            }
                            .stroke(
                                Color.green,
                                style: StrokeStyle(lineWidth: 5, lineCap: .round, dash: [5, 3])
                            )
                        }
                        
                        if let ringTip = hand.joints[.ringTip],
                           let thumbTip = hand.joints[.thumbTip],
                           hand.gesture == .pinchRing {
                            Path { path in
                                path.move(to: CGPoint(x: ringTip.location.x * width, y: ringTip.location.y * height))
                                path.addLine(to: CGPoint(x: thumbTip.location.x * width, y: thumbTip.location.y * height))
                            }
                            .stroke(
                                Color.green,
                                style: StrokeStyle(lineWidth: 5, lineCap: .round, dash: [5, 3])
                            )
                        }
                        
                        if let littleTip = hand.joints[.littleTip],
                           let thumbTip = hand.joints[.thumbTip],
                           hand.gesture == .pinchPinky {
                            Path { path in
                                path.move(to: CGPoint(x: littleTip.location.x * width, y: littleTip.location.y * height))
                                path.addLine(to: CGPoint(x: thumbTip.location.x * width, y: thumbTip.location.y * height))
                            }
                            .stroke(
                                Color.green,
                                style: StrokeStyle(lineWidth: 5, lineCap: .round, dash: [5, 3])
                            )
                        }
                        
                        // Draw joints as glowing dots
                        ForEach(Array(hand.joints.values)) { joint in
                            let x = joint.location.x * width
                            let y = joint.location.y * height
                            
                            Circle()
                                .fill(getJointColor(jointId: joint.id, activeGesture: hand.gesture))
                                .frame(width: 8, height: 8)
                                .shadow(color: .cyan, radius: 4)
                                .position(x: x, y: y)
                        }
                    }
                }
                
                // Status Overlay Banner
                VStack {
                    Spacer()
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.cyan)
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
            .aspectRatio(9.0/16.0, contentMode: .fit)
            .background(Color.black.opacity(0.3))
            .cornerRadius(24)
        }
    }
    
    // MARK: - Gesture Dashboard View
    
    private var gestureDashboardView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Active Gestures")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(.white.opacity(0.8))
                .padding(.horizontal, 4)
            
            if let activeHand = manager.detectedHands.first {
                HStack(spacing: 16) {
                    // Large Gesture Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(activeHand.gesture != .none ? Color.green.opacity(0.15) : Color.white.opacity(0.05))
                            .frame(width: 60, height: 60)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(activeHand.gesture != .none ? Color.green.opacity(0.3) : Color.white.opacity(0.1), lineWidth: 1)
                            )
                        
                        Image(systemName: activeHand.gesture.icon)
                            .font(.title)
                            .foregroundColor(activeHand.gesture != .none ? .green : .white.opacity(0.4))
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(activeHand.gesture.rawValue)
                            .font(.headline)
                            .foregroundColor(activeHand.gesture != .none ? .green : .white)
                        
                        Text(activeHand.isLeftHand ? "Left Hand (Tangan Kiri)" : "Right Hand (Tangan Kanan)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                        
                        Text("Confidence: \(String(format: "%.0f%%", activeHand.confidence * 100))")
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    
                    Spacer()
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
    
    // MARK: - Distance Analytics
    
    private var distanceAnalyticsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Landmark Distance Analytics")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(.white.opacity(0.8))
                .padding(.horizontal, 4)
            
            VStack(spacing: 12) {
                if let hand = manager.detectedHands.first,
                   let thumbTip = hand.joints[.thumbTip],
                   let indexTip = hand.joints[.indexTip],
                   let middleTip = hand.joints[.middleTip],
                   let ringTip = hand.joints[.ringTip],
                   let littleTip = hand.joints[.littleTip] {
                    
                    // Distances
                    let t2i = hypot(thumbTip.location.x - indexTip.location.x, thumbTip.location.y - indexTip.location.y)
                    let t2m = hypot(thumbTip.location.x - middleTip.location.x, thumbTip.location.y - middleTip.location.y)
                    let t2r = hypot(thumbTip.location.x - ringTip.location.x, thumbTip.location.y - ringTip.location.y)
                    let t2l = hypot(thumbTip.location.x - littleTip.location.x, thumbTip.location.y - littleTip.location.y)
                    
                    DistanceBarRow(label: "Thumb ⟷ Index (Jempol - Telunjuk)", distance: t2i, isPinching: hand.gesture == .pinchIndex)
                    DistanceBarRow(label: "Thumb ⟷ Middle (Jempol - Tengah)", distance: t2m, isPinching: hand.gesture == .pinchMiddle)
                    DistanceBarRow(label: "Thumb ⟷ Ring (Jempol - Manis)", distance: t2r, isPinching: hand.gesture == .pinchRing)
                    DistanceBarRow(label: "Thumb ⟷ Little (Jempol - Kelingking)", distance: t2l, isPinching: hand.gesture == .pinchPinky)
                    
                } else {
                    Text("Metrics will appear here when a hand is tracked.")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.4))
                        .padding(.vertical, 20)
                }
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
    }
    
    // MARK: - Info Button
    
    private var infoButton: some View {
        Button(action: {
            showingInfoSheet = true
        }) {
            HStack {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                Text("Analyze Apple Vision Capabilities")
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.semibold)
            }
            .foregroundColor(.cyan)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(Color.cyan.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.cyan.opacity(0.2), lineWidth: 1)
            )
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Camera Permission View
    
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
                
                Text("This app uses Apple's Vision framework to track hand landmarks in real-time. We process frames entirely on-device.")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Button(action: {
                manager.checkPermissionAndStart()
            }) {
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
    
    // MARK: - Helper functions
    
    private func getJointColor(jointId: String, activeGesture: DetectedGesture) -> Color {
        // Change joint color based on active pinch gesture
        if jointId == VNHumanHandPoseObservation.JointName.thumbTip.rawValue.rawValue {
            return .green
        }
        if jointId == VNHumanHandPoseObservation.JointName.indexTip.rawValue.rawValue && activeGesture == .pinchIndex {
            return .green
        }
        if jointId == VNHumanHandPoseObservation.JointName.middleTip.rawValue.rawValue && activeGesture == .pinchMiddle {
            return .green
        }
        if jointId == VNHumanHandPoseObservation.JointName.ringTip.rawValue.rawValue && activeGesture == .pinchRing {
            return .green
        }
        if jointId == VNHumanHandPoseObservation.JointName.littleTip.rawValue.rawValue && activeGesture == .pinchPinky {
            return .green
        }
        return .cyan
    }
}

// MARK: - Distance Bar Component

struct DistanceBarRow: View {
    let label: String
    let distance: CGFloat
    let isPinching: Bool
    
    // Normalize distance for progress bar (under 0.20 is standard range)
    private var progressValue: Double {
        let maxDist: CGFloat = 0.20
        return Double(min(max(distance, 0), maxDist) / maxDist)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                
                Spacer()
                
                Text(String(format: "Dist: %.3f", distance))
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(isPinching ? .green : .white.opacity(0.5))
                    .fontWeight(isPinching ? .bold : .regular)
                
                if isPinching {
                    Text("PINCH!")
                        .font(.system(.caption2, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green)
                        .clipShape(Capsule())
                }
            }
            
            // Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isPinching ? Color.green : Color.cyan.opacity(0.6))
                        .frame(width: geo.size.width * CGFloat(progressValue), height: 8)
                        .shadow(color: isPinching ? .green : .cyan, radius: isPinching ? 4 : 0)
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - Vision Analysis Sheet View

struct VisionAnalysisSheet: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Title Image
                    ZStack {
                        LinearGradient(
                            colors: [.cyan.opacity(0.2), .purple.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .frame(height: 120)
                        
                        VStack(spacing: 8) {
                            Image(systemName: "visionpro")
                                .font(.system(size: 40))
                                .foregroundColor(.cyan)
                            Text("Apple Vision Hand Pose Analysis")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.bottom, 8)
                    
                    Group {
                        Text("1. Penjelasan Utama (Core Capabilities)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.cyan)
                        
                        Text("Apple Vision (`VNDetectHumanHandPoseRequest`) mendeteksi **21 titik sendi (landmarks)** pada tangan secara real-time langsung melalui kamera 2D biasa (RGB), tanpa memerlukan sensor kedalaman khusus (seperti LiDAR).")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("Sendi-sendi tersebut dibagi menjadi 5 grup jari + pergelangan tangan (wrist):")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            BulletRow(title: "Thumb (Jempol):", desc: "CMC, MP, IP, TIP (4 sendi)")
                            BulletRow(title: "Index Finger (Telunjuk):", desc: "MCP, PIP, DIP, TIP (4 sendi)")
                            BulletRow(title: "Middle Finger (Tengah):", desc: "MCP, PIP, DIP, TIP (4 sendi)")
                            BulletRow(title: "Ring Finger (Manis):", desc: "MCP, PIP, DIP, TIP (4 sendi)")
                            BulletRow(title: "Little Finger (Kelingking):", desc: "MCP, PIP, DIP, TIP (4 sendi)")
                            BulletRow(title: "Wrist (Pergelangan):", desc: "Titik pangkal tangan (1 sendi)")
                        }
                        .padding(.leading, 8)
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.2))
                    
                    Group {
                        Text("2. Bagaimana Vision Membedakan Pose?")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.cyan)
                        
                        Text("Apple Vision **tidak menyediakan** detektor gesture bawaan seperti 'Pinch Jempol-Telunjuk' atau 'Victory'. Vision hanya memberikan koordinat 2D ternormalisasi (0.0 sampai 1.0) untuk setiap sendi.")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("Untuk membedakan pose, kita menghitung **Jarak Euclidean (Pythagoras)** antar koordinat sendi secara manual di Swift:")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("d = √((x₂ - x₁)² + (y₂ - y₁)²)")
                            .font(.system(.body, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(8)
                        
                        Text("Aplikasi ini membedakan pose jempol-telunjuk vs jempol-tengah secara presisi dengan membandingkan jarak terpendek:")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                        
                        VStack(alignment: .leading, spacing: 8) {
                            BulletRow(title: "Pinch Jempol-Telunjuk:", desc: "Jarak antara `.thumbTip` ke `.indexTip` < 0.045.")
                            BulletRow(title: "Pinch Jempol-Tengah:", desc: "Jarak antara `.thumbTip` ke `.middleTip` < 0.045.")
                            BulletRow(title: "Pinch Jempol-Manis:", desc: "Jarak antara `.thumbTip` ke `.ringTip` < 0.045.")
                            BulletRow(title: "Pinch Jempol-Kelingking:", desc: "Jarak antara `.thumbTip` ke `.littleTip` < 0.045.")
                        }
                        .padding(.leading, 8)
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.2))
                    
                }
                .padding()
            }
            .background(Color(red: 0.08, green: 0.08, blue: 0.15).ignoresSafeArea())
            .navigationTitle("Vision Capabilities")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.cyan)
                }
            }
            .toolbarBackground(Color(red: 0.08, green: 0.08, blue: 0.15), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Helper Views for Sheet

struct BulletRow: View {
    let title: String
    let desc: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Text("•")
                .foregroundColor(.cyan)
                .fontWeight(.bold)
            Text(title)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            Text(desc)
                .foregroundColor(.white.opacity(0.7))
            Spacer()
        }
        .font(.caption)
    }
}

struct ComparisonRow: View {
    let title: String
    let desc: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.green)
            Text(desc)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .lineSpacing(4)
        }
        .padding()
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

