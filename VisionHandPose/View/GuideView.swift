//
//  GuideView.swift
//  VisionHandPose
//
//  Created by Dylan Amadeus on 14/07/26.
//

import SwiftUI

enum TutorialPart: String, CaseIterable, Identifiable {
    case hand = "Position Your Hand"
    case camera = "Open Camera View"
    case chords = "Chord Guides"
    case strumming = "How to Strum"
    case settings = "Customize Your Experience"

    var id: Self { self }
}

struct GuideView: View {
    @Binding var path: NavigationPath
    @State private var selectedPart: TutorialPart = .hand
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            
            HStack {
                ZStack {
                    Color("PrimaryBackground")
                        .ignoresSafeArea()
                    
                    VStack(alignment: .leading) {
                        VStack(alignment: .leading) {
                            Text("G E T T I N G   S T A R T E D")
                                .font(.custom("Inter", size: 13))
                                .fontWeight(.medium)
                                .foregroundStyle(Color("SecondaryFont"))
                            
                            Text("How to")
                                .font(.custom("Playfair Display", size: 75))
                                .fontWeight(.black)
                                .foregroundStyle(Color("PrimaryFont"))
                            Text("Play")
                                .font(.custom("Playfair Display", size: 75))
                                .italic()
                                .fontWeight(.black)
                                .foregroundStyle(Color("PrimaryFont"))
                        }
                        .padding(.leading, 30)
                        
                        VStack(alignment: .leading) {
                            ForEach(Array(TutorialPart.allCases.enumerated()), id: \.element) { index, part in
                                Button {
                                    selectedPart = part
                                } label: {
                                    HStack {
                                        Text("0\(index+1)")
                                            .font(.custom("Playfair Display", size: 25))
                                            .fontWeight(.bold)
                                            .padding(.trailing, 30)
                                            .padding(.top, -5)
                                            .padding(.leading, 30)
                                        Text(part.rawValue)
                                            .font(.custom("Inter", size: 25))
                                            .fontWeight(.medium)
                                    }
                                    .foregroundStyle(
                                        selectedPart == part ? Color("PrimaryFont") : Color("PrimaryFont").opacity(0.3)
                                    )
                                    .padding(.vertical, 30)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background {
                                        if selectedPart == part {
                                            LinearGradient(
                                                colors: [Color("SecondaryFont").opacity(0.5), Color("PrimaryBackground")],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        } else {
                                            Color.clear
                                        }
                                    }
                                    .overlay(alignment: .leading) {
                                        if(selectedPart == part) {
                                            Rectangle()
                                                .fill(Color("SecondaryFont"))
                                                .frame(width: 3)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .frame(width: 0.4*w)
                
                ZStack {
                    Color("PrimaryFont")
                        .ignoresSafeArea()
                    
                    switch selectedPart {
                    case .hand:
                        GuideCard(
                            number: 1,
                            logo: "hand.raised",
                            title: selectedPart.rawValue,
                            subtitle: "Make sure both of your hands are in the right spots and visible on camera. Ensure your chord-shaping hand is clearly visible in the Chord Zone, and your strumming hand is in the Strumming Zone. Good lighting will significantly improve detection accuracy.",
                            tip: "Natural light is best, but any light will do"
                        )
                    case .camera:
                        GuideCard(
                            number: 2,
                            logo: "camera",
                            title: selectedPart.rawValue,
                            subtitle: "To give you the best experience, StrumMe uses your device’s front camera to detect your hands and map them onto the virtual guitar. This is how the app checks your chords and strumming in real-time! Because of this, enabling camera permissions is a must. Don't worry, we only use the camera for gameplay, and your privacy is always protected.",
                            tip: "No internet needed - 100% on-device"
                        )
                    case .chords:
                        ChordGuides()

                    case .strumming:
                        GuideCard(
                            number: 4,
                            logo: "guitars",
                            title: selectedPart.rawValue,
                            subtitle: "Position and prepare your strumming hand over the designated strumming zone. Make sure your wrist is relaxed and ready to move, as the camera needs to track your hand's to register your strums on the strings.",
                            tip: "Try strumming all 6 strings slowly"
                        )
                    case .settings:
                        GuideCard(
                            number: 5,
                            logo: "gearshape",
                            title: selectedPart.rawValue,
                            subtitle: "Left-handed? You can easily switch layout modes by tapping the button in the top-right corner of the camera screen. This will mirror the detection zones to comfortably match your playing style.",
                            tip: "Only about 10% of the world is left-handed"
                        )
                    }
                }
            }
        }
    }
}

#Preview {
    GuideView(path: .constant(NavigationPath()))
}
