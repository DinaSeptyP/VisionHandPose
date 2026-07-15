//
//  MainGuitarView.swift
//  VisionHandPose
//
//  Created by Dylan Amadeus on 14/07/26.
//

import SwiftUI

struct MainGuitarView: View {
    @Binding var path: NavigationPath
    @ObservedObject var manager: HandPoseManager
    @ObservedObject var chordPlayer: ChordPlayer
    @State private var stringVibrations: [CGFloat] = [0, 0, 0, 0, 0, 0]
    @State private var lastTriggeredStrings: [Bool] = [false, false, false, false, false, false]
    @State private var isLandscape = false
    
    var body: some View {
        Group {
            if manager.cameraPermissionGranted {
                if isLandscape {
                    ZStack {
                        Color.black.opacity(0.2)
                            .ignoresSafeArea()
                        CameraPreviewView(session: manager.session)
                        
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
                                y: 25
                            )
                            ZoneLabelView(
                                title: manager.isRightHanded ? "Strumming Pattern" : "Chord",
                                color: manager.isRightHanded ? Color("SecondaryFont") : Color("PrimaryBrown"),
                                x: w*0.75,
                                y:25
                            )
                            
                            if let cHand = manager.chordHand {
                                drawHandSkeleton(cHand, width: w, height: h, color: .primaryBrown)
                            }
                            
                            if let sHand = manager.strumHand {
                                drawHandSkeleton(sHand, width: w, height: h, color: .secondaryFont)
                            }
                            
                            let startX = manager.isRightHanded ? w * 0.52 : w * 0.05
                            let endX = manager.isRightHanded ? w * 0.95 : w * 0.48
                            let stringYPositions: [CGFloat] = [0.40, 0.44, 0.48, 0.52, 0.56, 0.60]
                            
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
                                    lastTriggeredStrings[i] ? Color("PrimaryBrown") : Color.white.opacity(0.6),
                                    lineWidth: lastTriggeredStrings[i] ? 4.0 : 1.5
                                )
                                .shadow(color: lastTriggeredStrings[i] ? .primaryBrown : .clear, radius: 8)
                                
                                let textX = manager.isRightHanded ? w * 0.54 : w * 0.42
                                let noteLabel = manager.activeChord.guitarStrings[i]
                                if !noteLabel.isEmpty {
                                    Text(noteLabel)
                                        .font(.custom("Playfair Display", size: 9))
                                        .fontWeight(.bold)
                                        .fontDesign(.rounded)
                                        .foregroundColor(Color("PrimaryFont"))
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 1)
                                        .background(lastTriggeredStrings[i] ? Color("PrimaryFont") : Color.black.opacity(0.5))
                                        .cornerRadius(3)
                                        .position(x: textX, y: stringY - 8)
                                }
                            }
                        }
                        VStack {
                            Spacer()
                            HStack {
                                Circle()
                                    .fill(manager.chordHand != nil ? Color.green : Color.red)
                                    .frame(width: 6, height: 6)
                                Text(manager.statusMessage)
                                    .font(.custom("Playfair Display", size: 15))
                                    .fontDesign(.monospaced)
                                    .foregroundColor(Color("PrimaryFont"))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color("PrimaryDark").opacity(0.7))
                            .clipShape(Capsule())
                            .padding(.bottom, 12)
                        }
                        .aspectRatio(isLandscape ? 16.0 / 9.0 : 9.0 / 16.0, contentMode: .fit)
                        .cornerRadius(24)
                    }
                }
            } else {
                PermissionRequestView(manager: manager)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            forceLandscape()
            updateOrientation()
            manager.checkPermissionAndStart()
        }
        .onDisappear {
            manager.stopSession()
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: { manager.isRightHanded.toggle() }) {
                    HStack {
                        Image(systemName: "hand.raised.fill")
                        Text(manager.isRightHanded ? "Right-Handed" : "Left-Handed")
                    }
                    .font(.custom("Inter", size: 13))
                    .foregroundStyle(Color("PrimaryBrown"))
                }
            }
            ToolbarItem(placement: .principal) {
                Text("StrumMe")
                    .font(.custom("Playfair Display", size: 30))
                    .fontWeight(.bold)
                    .foregroundStyle(Color("PrimaryDark"))
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(value: "Guide") {
                    Text("\(Image(systemName: "info.circle"))")
                        .foregroundStyle(Color("PrimaryBrown"))
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            updateOrientation()
            manager.updateVideoOrientation()
        }
        .onReceive(manager.stringPluckedSubject) { stringIndex in
            triggerStrumAction(for: stringIndex)
        }
    }
}

#Preview {
    MainGuitarView(path: .constant(NavigationPath()), manager: HandPoseManager(), chordPlayer: ChordPlayer())
}
