//
//  ChordGuides.swift
//  VisionHandPose
//
//  Created by Muhamad Yuan Sastro Dimianta on 16/07/26.
//

import SwiftUI

struct HandPositionsGuides: View {
    let chords = ["ChordHand","StrummingHand"]
    let chordTypes = ["Major","Minor","Major7","Minor7"]
    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading) {
                    GuideHeading(
                        number: 3,
                        logo: "music.pages",
                        title: "Chord Guides",
                        subtitle: "Positioning your hands on the chords and strumming position",
                        titleSize: min(width * 0.07, 54),
                        numberSize: min(width * 0.15, 120),
                        iconSize: min(width * 0.045, 32),
                        subtitleSize: min(width * 0.03, 22)
                    )
                    .padding(.bottom)
                    
                    VStack (alignment: .leading) {
                        HStack(spacing: 100){
                            ForEach(chords, id: \.self) { chord in
                                HandPositionCard(chord: chord)
                                    .padding(.horizontal, 5)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 50)
                    
                    GuideTipCard(tip: "Greater Camera View, Easy Chord Recognition")
                        .padding(.bottom, 100)
                }
                .padding()
                .padding(.top, -50)
            }
        }
    }
}

#Preview {
    HandPositionsGuides()
}
