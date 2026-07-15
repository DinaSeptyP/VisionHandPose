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
                            logo: "guitars",
                            title: selectedPart.rawValue,
                            subtitle: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.",
                            tip: "Lorem ipsum dolor sit amet"
                        )
                    case .camera:
                        GuideCard(
                            number: 2,
                            logo: "camera",
                            title: selectedPart.rawValue,
                            subtitle: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.",
                            tip: "Lorem ipsum dolor sit amet"
                        )
                    case .chords:
                        GuideCard(
                            number: 3,
                            logo: "music.pages",
                            title: selectedPart.rawValue,
                            subtitle: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.",
                            tip: "Lorem ipsum dolor sit amet"
                        )
                    case .strumming:
                        GuideCard(
                            number: 4,
                            logo: "music.note.list",
                            title: selectedPart.rawValue,
                            subtitle: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.",
                            tip: "Lorem ipsum dolor sit amet"
                        )
                    case .settings:
                        GuideCard(
                            number: 5,
                            logo: "gearshape",
                            title: selectedPart.rawValue,
                            subtitle: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.",
                            tip: "Lorem ipsum dolor sit amet"
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
