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
    let tip: String

    @ObservedObject var manager: HandPoseManager
    
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
                        .frame(height: height * 0.70)
                }
                .background(Color("PrimaryFont"))
            }
        }
    }
}

extension CameraGuideCard {
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
    }
}

#Preview {
    
    CameraGuideCard(
        number: 1,
        logo: "camera.fill",
        title: "Camera Verification",
        tip: "Ensure your hands are fully visible and well-lit.",
        manager: HandPoseManager()
    )
}
