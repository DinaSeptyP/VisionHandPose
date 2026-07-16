//
//  PermissionRequestView.swift
//  VisionHandPose
//
//  Created by Dylan Amadeus on 15/07/26.
//

import SwiftUI

struct PermissionRequestView: View {
    @ObservedObject var manager: HandPoseManager
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.fill")
                .font(.custom("Playfair Display", size: 50))
                .fontWeight(.black)
                .foregroundColor(Color("SecondaryFont"))
            Text("Camera Permissions Denied")
                .font(.custom("Playfair Display", size: 20))
                .fontWeight(.bold)
            Text("Please enable camera settings in your iOS/iPadOS settings to play.")
                .font(.custom("Inter", size: 12))
                .fontWeight(.light)
                .foregroundColor(Color("SecondaryFont").opacity(0.6))
                .multilineTextAlignment(.center)
            Button("Grant Permission") {
                manager.checkPermissionAndStart()
            }
            .buttonStyle(.borderedProminent)
            .tint(Color("SecondaryFont"))
        }
        .padding()

    }
}

#Preview {
    PermissionRequestView(manager: HandPoseManager())
}
