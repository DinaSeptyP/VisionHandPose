import SwiftUI
import AVFoundation

struct SettingsView: View {
    @ObservedObject var manager: HandPoseManager
    @ObservedObject var chordPlayer: ChordPlayer
    
    @State private var showingInfoAlert = false
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Hand Tracking Calibration")) {
                    // Handedness Setting
                    HStack {
                        Image(systemName: "hand.raised.fill")
                            .foregroundColor(.cyan)
                            .frame(width: 24)
                        Toggle("Right-Handed Player", isOn: $manager.isRightHanded)
                    }
                    
                    // Camera Selection
                    HStack {
                        Image(systemName: "camera.fill")
                            .foregroundColor(.cyan)
                            .frame(width: 24)
                        
                        Picker("Tracking Camera", selection: $manager.activeCameraPosition) {
                            Text("Front Camera").tag(AVCaptureDevice.Position.front)
                            Text("Rear Camera").tag(AVCaptureDevice.Position.back)
                        }
                        .pickerStyle(.menu)
                        .onChange(of: manager.activeCameraPosition) { _, _ in
                            manager.startSession()
                        }
                    }
                }
                
                Section(header: Text("Framework Technical Analysis")) {
                    NavigationLink(destination: FrameworkDetailsView()) {
                        HStack {
                            Image(systemName: "doc.text.magnifyingglass")
                                .foregroundColor(.purple)
                                .frame(width: 24)
                            Text("Vision")
                        }
                    }
                    
                    NavigationLink(destination: JointListDetailsView()) {
                        HStack {
                            Image(systemName: "hand.point.up.left.fill")
                                .foregroundColor(.purple)
                                .frame(width: 24)
                            Text("Vision 21-Landmark Spec Sheet")
                        }
                    }
                }
                
                Section(header: Text("About App")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("2.0.0 (Native Apple UX)")
                            .foregroundColor(.white.opacity(0.5))
                    }
                    
                    HStack {
                        Text("Framework")
                        Spacer()
                        Text("Pure Apple Vision")
                            .foregroundColor(.cyan)
                            .fontWeight(.semibold)
                    }
                    
                    Button(action: { showingInfoAlert = true }) {
                        Text("Reset Settings to Default")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Guitar App Settings")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Settings Reset", isPresented: $showingInfoAlert) {
                Button("OK", role: .cancel) {
                    manager.isRightHanded = true
                    manager.activeCameraPosition = .front
                    manager.startSession()
                }
            } message: {
                Text("Your calibration preferences have been reset.")
            }
        }
    }
}

// MARK: - Sub-detail Views for Settings

struct FrameworkDetailsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Apple Vision Core Capabilities")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.cyan)
                
                Text("This app runs entirely on native Apple API requests (`VNDetectHumanHandPoseRequest`). Vision leverages local machine learning to compute the 2D coordinate positions of 21 hand joints on-device via the Apple Neural Engine.")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                
                Divider().background(Color.white.opacity(0.1))
                
            }
            .padding()
        }
        .navigationTitle("Vision Architecture")
        .background(Color(red: 0.05, green: 0.05, blue: 0.12).ignoresSafeArea())
    }
}

struct FrameworkComparisonCard: View {
    let title: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.green)
            Text(description)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .lineSpacing(4)
        }
        .padding()
        .background(Color.white.opacity(0.04))
        .cornerRadius(12)
    }
}

struct JointListDetailsView: View {
    let list: [String] = [
        "1. WRIST (Pergelangan Tangan)",
        "2. THUMB CMC (Ibu Jari - Pangkal)",
        "3. THUMB MP (Ibu Jari - Buku Tengah)",
        "4. THUMB IP (Ibu Jari - Sendi Ujung)",
        "5. THUMB TIP (Ibu Jari - Ujung)",
        "6. INDEX MCP (Telunjuk - Pangkal)",
        "7. INDEX PIP (Telunjuk - Buku Tengah)",
        "8. INDEX DIP (Telunjuk - Sendi Ujung)",
        "9. INDEX TIP (Telunjuk - Ujung)",
        "10. MIDDLE MCP (Tengah - Pangkal)",
        "11. MIDDLE PIP (Tengah - Buku Tengah)",
        "12. MIDDLE DIP (Tengah - Sendi Ujung)",
        "13. MIDDLE TIP (Tengah - Ujung)",
        "14. RING MCP (Manis - Pangkal)",
        "15. RING PIP (Manis - Buku Tengah)",
        "16. RING DIP (Manis - Sendi Ujung)",
        "17. RING TIP (Manis - Ujung)",
        "18. LITTLE MCP (Kelingking - Pangkal)",
        "19. LITTLE PIP (Kelingking - Buku Tengah)",
        "20. LITTLE DIP (Kelingking - Sendi Ujung)",
        "21. LITTLE TIP (Kelingking - Ujung)"
    ]
    
    var body: some View {
        List {
            Section(header: Text("21 Landmarks Tracked Per Hand")) {
                ForEach(list, id: \.self) { joint in
                    Text(joint)
                        .font(.system(.body, design: .rounded))
                }
            }
        }
        .navigationTitle("Landmark Spec Sheet")
    }
}
