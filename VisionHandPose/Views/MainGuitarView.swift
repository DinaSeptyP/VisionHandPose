//
//  MainGuitarView.swift
//  VisionHandPose
//
//  Created by Dylan Amadeus on 14/07/26.
//

import SwiftUI

struct MainGuitarView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var path: NavigationPath
    @ObservedObject var manager: HandPoseManager
    @ObservedObject var chordPlayer: ChordPlayer
    @State private var stringVibrations: [CGFloat] = [0, 0, 0, 0, 0, 0]
    @State private var lastTriggeredStrings: [Bool] = [false, false, false, false, false, false]

    var body: some View {
        HandTrackingExperienceView(manager: manager, chordPlayer: chordPlayer)
                    .ignoresSafeArea()
                    .navigationBarBackButtonHidden(true)
                    .onAppear {
                        forceLandscape()
                        updateOrientation()
                        manager.startIfCameraAlreadyAuthorized()
                    }
        .navigationBarBackButtonHidden(true)
        .onDisappear {
            manager.stopSession()
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("StrumMe")
                    .font(.custom("Playfair Display", size: 30))
                    .fontWeight(.bold)
                    .foregroundStyle(Color("PrimaryDark"))
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { manager.toggleHandedness() }) {
                    HStack {
                        Image(systemName: "hand.raised.fill")
                        Text(manager.isRightHanded ? "Right-Handed" : "Left-Handed")
                    }
                    .font(.custom("Inter", size: 13))
                    .foregroundStyle(Color("PrimaryBrown"))
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(value: "Guide") {
                    Text("\(Image(systemName: "info.circle"))")
                        .foregroundStyle(Color("PrimaryBrown"))
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            updateOrientation()
            manager.updateVideoOrientation()
        }
        
    }
}

#Preview {
    MainGuitarView(path: .constant(NavigationPath()), manager: HandPoseManager(), chordPlayer: ChordPlayer())
}
