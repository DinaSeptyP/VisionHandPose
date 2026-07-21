//
//  GuideView.swift
//  VisionHandPose
//
//  Created by Dylan Amadeus on 14/07/26.
//

import SwiftUI

enum TutorialPart: String, CaseIterable, Identifiable {
    case camera = "Open Camera View"
    case hand = "How to Play"
    case chords = "Chord Guides"
    case settings = "Customize Your Experience"
    
    var id: Self { self }
    
    var iconName: String {
        switch self {
        case .camera: return "camera.fill"
        case .hand: return "hand.raised.fill"
        case .chords: return "music.note.list"
        case .settings: return "gearshape.fill"
        }
    }
}

struct GuideView: View {
    @Binding var path: NavigationPath
    @State private var selectedPart: TutorialPart? = .camera
    @StateObject private var manager = HandPoseManager()
    @ObservedObject var chordPlayer: ChordPlayer
    
    var body: some View {
        NavigationSplitView {
            // Sidebar Navigation (Native Apple iPadOS Sidebar Style)
            List(TutorialPart.allCases, selection: $selectedPart) { part in
                NavigationLink(value: part) {
                    Label {
                        Text(part.rawValue)
                            .font(.custom("Inter-SemiBold", size: 16, relativeTo: .body))
                    } icon: {
                        Image(systemName: part.iconName)
                            .foregroundStyle(Color("SecondaryFont"))
                    }
                }
                .padding(.vertical, 8)
            }
            .listStyle(.sidebar)
            .navigationTitle("Getting Started")
            
        } detail: {
            // Detail Presentation Area (Floating inside system-styled card layout)
            ZStack {
                Color("PrimaryFont")
                    .ignoresSafeArea()
                
                if let part = selectedPart {
                    switch part {
                    case .camera:
                        CameraGuideCard(
                            number: 1,
                            logo: part.iconName,
                            title: part.rawValue,
                            subtitle: "Allow front camera access to scan your hand and finger movements.",
                            tip: "Place your device on a stable surface and avoid harsh backlighting for optimal tracking.",
                            manager: manager
                        )
                        
                    case .hand:
                        HowToPlayCard(
                            number: 2,
                            logo: part.iconName,
                            title: part.rawValue,
                            subtitle: "Position your left hand on the left zone to hold chords, and pinch your right index finger and thumb on the right zone to strum strings.",
                            tip: "Perform a pinch gesture with your strumming hand to trigger virtual pick plucks.",
                            manager: manager,
                            chordPlayer: chordPlayer
                        )
                        
                    case .chords:
                        ChordGuides()
                        
                    case .settings:
                        CustomizeExperience(
                            number: 4,
                            logo: part.iconName,
                            title: part.rawValue,
                            tip: "Using the front camera allows you to view real-time hand skeleton tracking directly on screen.",
                            manager: manager,
                            chordPlayer: chordPlayer)
                    }
                } else {
                    ContentUnavailableView(
                        "Select a Guide",
                        systemImage: "book.pages",
                        description: Text("Select an option from the sidebar to start learning.")
                    )
                }
            }
        }
        .onDisappear {
            manager.stopSession()
        }
    }
}

#Preview {
    GuideView(path: .constant(NavigationPath()), chordPlayer: ChordPlayer())
}
