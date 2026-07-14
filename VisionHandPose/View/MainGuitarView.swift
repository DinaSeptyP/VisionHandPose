//
//  MainGuitarView.swift
//  VisionHandPose
//
//  Created by Dylan Amadeus on 14/07/26.
//

import SwiftUI

struct MainGuitarView: View {
    @ObservedObject var manager: HandPoseManager
    @ObservedObject var chordPlayer: ChordPlayer
    @State private var stringVibrations: [CGFloat] = [0, 0, 0, 0, 0, 0]
    @State private var lastTriggeredStrings: [Bool] = [false, false, false, false, false, false]
    
    var body: some View {
        ZStack {
            CameraPreviewView(session: manager.session)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [.primaryBrown.opacity(0.3), .secondaryFont.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
            
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                
                Path { path in
                    path.move(to: CGPoint(x: w * 0.5, y: 0))
                    path.addLine(to: CGPoint(x: w * 0.5, y: h))
                }
                .stroke(
                    LinearGradient(
                        colors: [.brown.opacity(0.1), .white.opacity(0.5), .brown.opacity(0.1)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    style: StrokeStyle(lineWidth: 1.5, dash: [8, 4])
                )
                
                ZoneLabelView(
                    title: manager.isRightHanded ? "Chord" : "Strumming Pattern",
                    color: manager.isRightHanded ? Color("PrimaryBrown") : Color("SecondaryFont"),
                    x: w*0.25,
                    y: 28
                )
                ZoneLabelView(
                    title: manager.isRightHanded ? "Strumming Pattern" : "Chord",
                    color: manager.isRightHanded ? Color("SecondaryFont") : Color("PrimaryBrown"),
                    x: w*0.75,
                    y: 28
                )
                
                if let cHand = manager.chordHand {
                    drawHandSkeleton(cHand, width: w, height: h, color: .primaryBrown)
                }
                
                if let sHand = manager.strumHand {
                    drawHandSkeleton(sHand, width: w, height: h, color: .secondaryFont)
                }
                
                let startX = manager.isRightHanded ? w * 0.52 : w * 0.05
                let endX = manager.isRightHanded ? w * 0.95 : w * 0.48
                let stringYPositions: [CGFloat] = [0.35, 0.41, 0.47, 0.53, 0.59, 0.65]
                
                ForEach(0..<6) { i in
                    let stringY = stringYPositions[i] * h
                    let vibration = stringVibrations[i]
                    
                    Path { path in
                        path.move(to: CGPoint(x: startX, y: stringY))
                        path.addQuadCurve(
                            to: CGPoint(x: endX, y: stringY),
                            control: CGPoint(x: (startX + endX) / 2, y: stringY + vibration)
                        )
                    }
                    .stroke(
                        lastTriggeredStrings[i] ? Color.green : Color.white.opacity(0.6),
                        lineWidth: lastTriggeredStrings[i] ? 4.0 : 1.5
                    )
                    .shadow(color: lastTriggeredStrings[i] ? .primaryBrown : .clear, radius: 8)
                    
                    // Hovering Note indicator
                    let textX = manager.isRightHanded ? w * 0.54 : w * 0.42
                    let noteLabel = manager.activeChord.guitarStrings[i]
                    if !noteLabel.isEmpty {
                        Text(noteLabel)
                            .font(.custom("Inter", size: <#T##CGFloat#>))
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(lastTriggeredStrings[i] ? Color.green : Color.black.opacity(0.5))
                            .cornerRadius(3)
                            .position(x: textX, y: stringY - 8)
                    }
                }
                
            }
            
            
        }
    }
}

#Preview {
    MainGuitarView(manager: HandPoseManager(), chordPlayer: ChordPlayer())
}
