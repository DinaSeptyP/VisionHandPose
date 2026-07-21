//
//  CustomizeExperience.swift
//  VisionHandPose
//
//  Created by Syahra Zulya Shania Maghfiroh on 19/07/26.
//

import SwiftUI

// Wrapper - design GuideCard & live HandTrackingExperienceView
struct CustomizeExperience: View {
    let number: Int
    let logo: String
    let title: String
    let tip: String

    @ObservedObject var manager: HandPoseManager
    @ObservedObject var chordPlayer: ChordPlayer
    
    @State private var customizeStep = 0
    @State private var hasChangedHandedness = false
    @State private var hasResizedStrings = false
    @State private var hasMovedStrings = false
    
    private var dynamicTip: String {
        switch customizeStep {
        case 0:
            return "Choose Left-Handed or Right-Handed from the toolbar."
        case 1:
            return "Resize the string spacing by dragging the top or bottom string handle circles."
        case 2:
            return "Move the string position by dragging the strings into a comfortable area."
        default:
            return "Setup your preferred tuning and finger placement."
        }
    }
    
    var body: some View {
        GeometryReader { geo in
            let height = geo.size.height
            
            ScrollView {
                GuideCard(
                    number: number,
                    logo: logo,
                    title: title,
                    tip: dynamicTip
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
    
    private func updateCustomizeStep() {
        if customizeStep == 0, hasChangedHandedness {
            customizeStep = 1
        }

        if customizeStep == 1, hasResizedStrings {
            customizeStep = 2
        }

        if customizeStep == 2, hasMovedStrings {
            customizeStep = 3
        }
    }
    
}



extension CustomizeExperience {
    private var cameraSection: some View {
        Group {
            if manager.cameraPermissionGranted {
                HandTrackingExperienceView(
                    manager: manager,
                    chordPlayer: chordPlayer,
                    onStrumPositionChanged: {
                        hasMovedStrings = true
                        updateCustomizeStep()
                    },
                    onStringSpacingChanged: {
                        hasResizedStrings = true
                        updateCustomizeStep()
                    }
                )
                    .overlay(alignment: .top) {
                        cameraToolbar
                            .padding(.top, 8)
                    }
            } else {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.black.opacity(0.04))
                    .overlay {
                        PermissionRequestView(manager: manager)
                        
                    }
            }
        }
    }
    
    private var cameraToolbar: some View {
            ZStack {
                HStack {
                    Spacer()

                    HStack(spacing: 12) {
                        Button {
                            manager.toggleHandedness()
                            hasChangedHandedness = true
                            updateCustomizeStep()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "hand.raised.fill")
                                Text(manager.isRightHanded ? "Right-Handed" : "Left-Handed")
                            }
                            .font(.custom("Inter", size: 13))
                            .foregroundStyle(Color("PrimaryBrown"))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 36)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .padding(.horizontal, 12)
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
    CustomizeExperience(
        number: 2,
        logo: "hand.raised.fill",
        title: "How to Play",
        tip: "Keep both hands within their respective screen zones.",
        manager: HandPoseManager(),
        chordPlayer: ChordPlayer()
    )
}
