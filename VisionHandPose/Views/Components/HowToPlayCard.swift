//
//  GuideCard.swift
//  VisionHandPose
//
//  Created by Dylan Amadeus on 15/07/26.
//

import SwiftUI

// Wrapper - design GuideCard & live HandTrackingExperienceView
struct HowToPlayCard: View {
    let number: Int
    let logo: String
    let title: String
    let subtitle: String
    let tip: String

    @ObservedObject var manager: HandPoseManager
    @ObservedObject var chordPlayer: ChordPlayer
    
    var body: some View {
        ScrollView {
            GuideCard(
                number: number,
                logo: logo,
                title: title,
                subtitle: subtitle,
                tip: tip
            ) {
                cameraSection
            }
        }
        .background(Color("PrimaryFont"))
        .onAppear {
            manager.checkPermissionAndStart()
        }
    }

    private var cameraSection: some View {
        Group {
            if manager.cameraPermissionGranted {
                HandTrackingExperienceView(manager: manager, chordPlayer: chordPlayer)
            } else {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.black.opacity(0.04))
                    .overlay {
                        PermissionRequestView(manager: manager)
                    }
            }
        }
        .frame(height: 380)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

#Preview {
    HowToPlayCard(
        number: 2,
        logo: "hand.raised.fill",
        title: "How to Play",
        subtitle: "Practice forming chords with your left hand and strumming with your right hand.",
        tip: "Keep both hands within their respective screen zones.",
        manager: HandPoseManager(),
        chordPlayer: ChordPlayer()
    )
}
