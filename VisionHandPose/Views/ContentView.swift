import SwiftUI

struct ContentView: View {
    @StateObject private var manager = HandPoseManager()
    @StateObject private var chordPlayer = ChordPlayer()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            PlayView(manager: manager, chordPlayer: chordPlayer)
                .tabItem {
                    Label("Air Guitar", systemImage: "guitar.fill")
                }
                .tag(0)
            
            PracticeView(manager: manager, chordPlayer: chordPlayer)
                .tabItem {
                    Label("Fretboard", systemImage: "music.note.list")
                }
                .tag(1)
            
            LandmarksView(manager: manager)
                .tabItem {
                    Label("Vision Analysis", systemImage: "hand.point.up.left.fill")
                }
                .tag(2)
            
            SettingsView(manager: manager, chordPlayer: chordPlayer)
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .tint(.cyan)
        .preferredColorScheme(.dark)
        .onAppear {
            forceLandscape()
        }
    }
    
    private func forceLandscape() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        let preferences = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .landscape)
        windowScene.requestGeometryUpdate(preferences) { error in
            print("Failed to force landscape: \(error.localizedDescription)")
        }
    }
}
