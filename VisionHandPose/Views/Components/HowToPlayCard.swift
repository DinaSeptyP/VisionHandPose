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
    let tip: String

    @ObservedObject var manager: HandPoseManager
    @ObservedObject var chordPlayer: ChordPlayer
    
    var body: some View {
        GeometryReader { geo in
            let height = geo.size.height
            
            ScrollView {
                GuideCard(
                    number: number,
                    logo: logo,
                    title: title,
                    tip: tip
                ) {
                    cameraSection
                        .frame(height: height * 0.65)
                }
            }
            .background(Color("PrimaryFont"))
            .onAppear {
                manager.checkPermissionAndStart()
            }
        }
    }
}

extension HowToPlayCard {
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
    }

    private var tipSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "lightbulb.max")

            Text("Tip: \(tip)")
        }
        .font(.custom("Inter", size: 18))
        .foregroundStyle(Color("PrimaryBrown"))
        .padding()
        .background(Color("SecondaryFont").opacity(0.1))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
            .stroke(Color("SecondaryFont"),lineWidth: 0.5)
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
        tip: "Keep both hands within their respective screen zones.",
        manager: HandPoseManager(),
        chordPlayer: ChordPlayer()
    )
}
