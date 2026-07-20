//
//  GuideCard.swift
//  VisionHandPose
//
//  Created by Dylan Amadeus on 15/07/26.
//

import SwiftUI

// Wrapper - GuideCard design & live CameraPreview view
struct CameraGuideCard: View {
    let number: Int
    let logo: String
    let title: String
    let subtitle: String
    let tip: String

    @ObservedObject var manager: HandPoseManager

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
    }

    private var cameraSection: some View {
        Group {
            if manager.cameraPermissionGranted {
                CameraPreviewView(session: manager.session)
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
    CameraGuideCard(
        number: 1,
        logo: "camera.fill",
        title: "Camera Verification",
        subtitle: "Allow front camera access to enable real-time hand gesture tracking.",
        tip: "Ensure your hands are fully visible and well-lit.",
        manager: HandPoseManager()
    )
}
