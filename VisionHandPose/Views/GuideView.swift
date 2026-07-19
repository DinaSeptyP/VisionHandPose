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
}

struct GuideView: View {
    @Binding var path: NavigationPath
    @State private var selectedPart: TutorialPart = .camera
    @StateObject private var manager = HandPoseManager()
    @ObservedObject var chordPlayer: ChordPlayer
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let panelWidth = 0.4 * w
            let panelHeight = geo.size.height
            
            let eyebrowSize = min(panelWidth * 0.028, 13)
            let titleSize = min(panelWidth * 0.16, 75)
            let backButtonSize = min(panelWidth * 0.085, 40)
            let itemNumberSize = min(panelWidth * 0.055, 25)
            let itemLabelSize = min(panelWidth * 0.055, 25)
            let itemVPadding = min(panelHeight * 0.028, 30)
            let sidePadding = min(panelWidth * 0.065, 30)
            
            HStack {
                ZStack {
                    Color("PrimaryBackground")
                        .ignoresSafeArea()
                    
                    VStack(alignment: .leading) {
                        
                        HStack {
                            Button {
                                if !path.isEmpty {
                                    path.removeLast()
                                }
                            } label: {
                                Image(systemName: "chevron.left")
                                    .font(
                                        .system(
                                            size: backButtonSize * 0.32,
                                            weight: .semibold
                                        )
                                    )
                                    .foregroundStyle(Color("PrimaryFont"))
                                    .frame(
                                        width: backButtonSize,
                                        height: backButtonSize
                                    )
                                    .background(Color("PrimaryFont").opacity(0.08))
                                    .clipShape(Circle())
                            }
                            Spacer()
                        }
                        .padding(.horizontal, sidePadding)
                        //                        .padding(.top, 12)
                        
                        VStack(alignment: .leading) {
                            Text("G E T T I N G   S T A R T E D")
                                .font(.custom("Inter", size: eyebrowSize))
                                .fontWeight(.medium)
                                .foregroundStyle(Color("SecondaryFont"))
                            
                            Text("How to")
                                .font(
                                    .custom("Playfair Display", size: titleSize)
                                )
                                .fontWeight(.black)
                                .foregroundStyle(Color("PrimaryFont"))
                            Text("Play")
                                .font(
                                    .custom("Playfair Display", size: titleSize)
                                )
                                .italic()
                                .fontWeight(.black)
                                .foregroundStyle(Color("PrimaryFont"))
                        }
                        .padding(.leading, sidePadding)
                        
                        VStack(alignment: .leading) {
                            ForEach(Array(TutorialPart.allCases.enumerated()), id: \.element) {
 index,
 part in
                                Button {
                                    selectedPart = part
                                } label: {
                                    HStack {
                                        Text("0\(index+1)")
                                            .font(
                                                .custom(
                                                    "Playfair Display",
                                                    size: itemNumberSize
                                                )
                                            )
                                            .fontWeight(.bold)
                                            .padding(.trailing, sidePadding)
                                            .padding(.top, -5)
                                            .padding(.leading, sidePadding)
                                        Text(part.rawValue)
                                            .font(
                                                .custom(
                                                    "Inter",
                                                    size: itemLabelSize
                                                )
                                            )
                                            .fontWeight(.medium)
                                    }
                                    .foregroundStyle(
                                        selectedPart == part ? Color("PrimaryFont") : Color("PrimaryFont").opacity(0.3)
                                    )
                                    .padding(.vertical, itemVPadding)
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
                .frame(width: panelWidth)
                
                ZStack {
                    Color("PrimaryFont")
                        .ignoresSafeArea()
                    
                    switch selectedPart {
                    case .camera:
                        CameraGuideCard(
                            number: 1,
                            logo: "guitars",
                            title: selectedPart.rawValue,
                            subtitle: "Allow camera permissions to access your camera.",
                            tip: "Lorem ipsum dolor sit amet",
                            manager: manager,
                        )
                        
                    case .hand:
                        HowToPlayCard(
                            number: 2,
                            logo: "camera",
                            title: selectedPart.rawValue,
                            subtitle: "place your hands on the chords and in the strumming position",
                            tip: "Lorem ipsum dolor sit amet",
                            manager: manager,
                            chordPlayer: chordPlayer
                        )
                        //                        GuideCard(
                        //                            number: 2,
                        //                            logo: "camera",
                        //                            title: selectedPart.rawValue,
                        //                            subtitle: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.",
                        //                            tip: "Lorem ipsum dolor sit amet"
                        //                        )
                        
                    case .chords:
                        ChordGuides()
                        
                    case .settings:
                        GuideCard(
                            number: 4,
                            logo: "gearshape",
                            title: selectedPart.rawValue,
                            subtitle: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.",
                            tip: "Lorem ipsum dolor sit amet"
                        )
                    }
                }
                //                .onAppear { manager.checkPermissionAndStart() }
                .onDisappear { manager.stopSession() }
            }
        }
        .navigationBarBackButtonHidden(true)
        //        .toolbar(.hidden, for: .navigationBar)
    }
}

#Preview {
    GuideView(path: .constant(NavigationPath()), chordPlayer: ChordPlayer())
}
