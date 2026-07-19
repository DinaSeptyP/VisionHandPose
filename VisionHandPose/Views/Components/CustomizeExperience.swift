//
//  CustomizeExperience.swift
//  VisionHandPose
//
//  Created by Syahra Zulya Shania Maghfiroh on 19/07/26.
//

import SwiftUI

private enum CustomizeStep {
    case chooseHand
    case moveStrum
    case ready
}

struct CustomizeExperience: View {
    let number: Int
    let logo: String
    let title: String
    let tip: String
    
    @ObservedObject var manager: HandPoseManager
    @ObservedObject var chordPlayer: ChordPlayer
    
    @State private var currentStep: CustomizeStep = .chooseHand
    @State private var showingCustomizeInfo = false
    
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
        .onChange(of: manager.isRightHanded) {
            withAnimation(.easeInOut(duration: 0.2)) {
                currentStep = .moveStrum
            }
        }
        .alert(
            "Customize Your Experience",
            isPresented: $showingCustomizeInfo
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(
                "Choose your playing hand, then drag the strings to a comfortable strumming position."
            )
        }
    }
}

extension CustomizeExperience {
    private var dynamicSubtitle: String {
        switch currentStep {
        case .chooseHand:
            return "Choose Right-Handed or Left-Handed to match your playing style."
        case .moveStrum:
            let side = manager.isRightHanded ? "right" : "left"
            
            return """
Great! Now drag the strumming strings on the \(side) side to a comfortable position
"""
            
        case .ready:
            return """
You're all set. Your handedness and strumming position are ready to use
"""
        }
    }
    
    private var headerSection: some View {
        GuidePageHeader(
            number: number,
            logo: logo,
            title: title,
            subtitle: dynamicSubtitle
        )
    }
    
    private var cameraSection: some View {
        Group {
            if manager.cameraPermissionGranted {
                HandTrackingExperienceView(
                    manager: manager,
                    chordPlayer: chordPlayer,
                    topContentInset: 48,
                    onStrumPositionChanged: {
                        guard currentStep == .moveStrum else { return }

                        withAnimation {
                            currentStep = .ready
                        }
                    }
                )
            } else {
                Color.black.opacity(0.08)
                    .overlay {
                        PermissionRequestView(manager: manager)
                    }
            }
        }
        .frame(height: 490)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(alignment: .top) {
            cameraToolbar
                .padding(.top, 8)
        }
    }

    private var cameraToolbar: some View {
        ZStack {
//            Text("StrumMe")
//                .font(.custom("Playfair Display", size: 30))
//                .fontWeight(.bold)
//                .foregroundStyle(Color("PrimaryDark"))

            HStack {
                Spacer()

                HStack(spacing: 12) {
                    Button {
                        manager.toggleHandedness()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "hand.raised.fill")
                            Text(manager.isRightHanded ? "Right-Handed" : "Left-Handed")
                        }
                        .font(.custom("Inter", size: 13))
                        .foregroundStyle(Color("PrimaryBrown"))
                    }
                    .buttonStyle(.plain)

                    Button {
                        showingCustomizeInfo = true
                    } label: {
                        Image(systemName: "info.circle")
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
        GuideTipCard(tip: "Tip: \(tip)")
    }
}

#Preview {
    CustomizeExperience(
        number: 4,
        logo: "gearshape",
        title: "Customize Your Experience",
        tip: "You can change this again",
        manager: HandPoseManager(),
        chordPlayer: ChordPlayer()
    )
}
