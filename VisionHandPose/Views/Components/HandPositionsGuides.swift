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
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading) {
                GuideHeading(number: 3, logo: "music.pages", title: "Chord Guides")
                
                
                
                VStack (alignment: .leading) {
                    Text("Positioning your hands on the chords and strumming position")
                        .font(.custom("Inter", size: 23))
                        .fontWeight(.regular)
                        .foregroundStyle(Color("PrimaryBackground"))
                        .padding(.bottom)
                    
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

#Preview {
    HandPositionsGuides()
}
