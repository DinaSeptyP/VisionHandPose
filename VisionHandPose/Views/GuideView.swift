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

//enum

struct GuideView: View {
    @StateObject private var manager = HandPoseManager()
    @ObservedObject var chordPlayer: ChordPlayer
    @State private var selectedPart: TutorialPart? = .camera
    @State private var howToPlayStep = 0
    @State private var hasStrummed = false
    @Binding var path: NavigationPath
    
    private var dynamicTip: String {
        switch howToPlayStep {
        case 0:
            return "Place your left hand on the chord zone"
        case 1:
            return "Now place your right hand on the strum zone"
        default:
            return "You're ready to play!, now check out the “Chord Guides” to learns how to play the chords"
        }
    }
    
    private var customExperience: String {
        switch howToPlayStep {
        case 0:
            return "Use the "
        case 1:
            return "Now place your right hand on the strum zone"
        case 2:
            return "Now place your right hand on the strum zone"
        default:
            return "You're ready to play!, now check out the “Chord Guides” to learns how to play the chords"
        }
    }
    
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
            .tint(Color("PrimaryBrown"))
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
                            tip: manager.cameraPermissionGranted ? "Great, now check out the “How to Play” guides to learn how to play" : "Grant permission to use your camera",
                            manager: manager
                        )
                        
                    case .hand:
                        HowToPlayCard(
                            number: 2,
                            logo: part.iconName,
                            title: part.rawValue,
                            tip: dynamicTip,
                            manager: manager,
                            chordPlayer: chordPlayer
                        )
                        .onDisappear {
                            howToPlayStep = 0
                        }
                        
                    case .chords:
                        ChordGuides()
                        
                    case .settings:
                        CustomizeExperience(
                            number: 4,
                            logo: part.iconName,
                            title: part.rawValue,
                            tip: "",
                            manager: manager,
                            chordPlayer: chordPlayer
                        )
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
            manager.cameraPermissionGranted = false
        }
        .onChange(of: manager.chordHand != nil) {
            updateHowToPlayStep()
        }
        .onChange(of: manager.strumHand != nil) {
            updateHowToPlayStep()
        }
    }
    
    private func updateHowToPlayStep() {
        if howToPlayStep == 0, manager.chordHand != nil {
            howToPlayStep = 1
        }

        if howToPlayStep == 1, manager.strumHand != nil {
            howToPlayStep = 2
        }
    }
    
}



#Preview {
    GuideView(chordPlayer: ChordPlayer(), path: .constant(NavigationPath()))
}
