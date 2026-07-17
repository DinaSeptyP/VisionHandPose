//
//  GuideCard.swift
//  VisionHandPose
//
//  Created by Dylan Amadeus on 15/07/26.
//

import SwiftUI

struct CameraGuideCard: View {
    
    let number: Int
    let logo: String
    let title: String
    let subtitle: String
    let tip: String

    @ObservedObject var manager: HandPoseManager
    
    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            
            let titleSize = min(width * 0.07, 54)
            let numberSize = min(width * 0.15, 120)
            let iconSize = min(width * 0.045, 32)
            let subtitleSize = min(width * 0.03, 22)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    GuideHeading(
                        number: number,
                        logo: logo,
                        title: title,
                        subtitle: subtitle,
                        titleSize: titleSize,
                        numberSize: numberSize,
                        iconSize: iconSize,
                        subtitleSize: subtitleSize
                    )
                    cameraSection
                        .frame(height: min(height * 0.42, 490))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    tipSection
                    Spacer(minLength: 0)
                }
                .padding(32)
            }
            .background(Color("PrimaryFont"))
        }
    }
}

extension CameraGuideCard {
    private var cameraSection: some View {
        Group {
            if manager.cameraPermissionGranted {
                CameraPreviewView(session: manager.session)
            } else {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.08))
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
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    
    CameraGuideCard(
        number: 1,
        logo: "guitars",
        title: "Open Camera View",
        subtitle: "Allow permission to access your camera.",
        tip: "Make sure your hands are visible to the camera.",
        manager: HandPoseManager()
    )
}
