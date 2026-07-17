//
//  GuideCard.swift
//  VisionHandPose
//
//  Created by Dylan Amadeus on 15/07/26.
//

import SwiftUI

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
            VStack(alignment: .leading, spacing: 24) {
                headerSection
                cameraSection
                tipSection
                Spacer(minLength: 0)
            }
            .padding(32)
        }
        .background(Color("PrimaryFont"))
        .onAppear {
            manager.checkPermissionAndStart()
        }
    }
}

extension HowToPlayCard {
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            ZStack(alignment: .leading) {
                Text("0\(number)")
                    .font(.custom("Playfair Display",size: 120))
                    .fontWeight(.black)
                    .foregroundStyle(Color("PrimaryBrown").opacity(0.15))

                Image(systemName: logo)
                    .font(.system(size: 32))
                    .foregroundStyle(.white)
                    .padding(20)
                    .background(Color("SecondaryFont"))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .offset(x: -0, y: 60)
            }

            Text(title)
                .font(.custom("Playfair Display",size: 54))
                .fontWeight(.black)
                .foregroundStyle(Color("PrimaryBackground"))

            Text(subtitle)
                .font(.custom("Inter", size: 22))
                .foregroundStyle(Color("PrimaryBackground"))
        }
    }

    private var cameraSection: some View {
        Group {
            if manager.cameraPermissionGranted {
                HandTrackingExperienceView(manager: manager, chordPlayer: chordPlayer)
            } else {
                RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.08))
                .overlay {
                    PermissionRequestView(manager: manager)
                }
            }
        }
        .frame(height: 490)
        .clipShape(RoundedRectangle(cornerRadius: 20))
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
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {

    HowToPlayCard(
        number: 1,
        logo: "guitars",
        title: "Open Camera View",
        subtitle: "Allow permission to access your camera.",
        tip: "Make sure your hands are visible to the camera.",
        manager: HandPoseManager(), chordPlayer: ChordPlayer()
    )
}
