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
        
        
        
        GeometryReader { geo in
            let height = geo.size.height
            
            ScrollView {
                GuideCard(
                    number: number,
                    logo: logo,
                    title: title,
                    subtitle: subtitle,
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
    
    CameraGuideCard(
        number: 1,
        logo: "camera.fill",
        title: "Camera Verification",
        subtitle: "Allow front camera access to enable real-time hand gesture tracking.",
        tip: "Ensure your hands are fully visible and well-lit.",
        manager: HandPoseManager()
    )
}
