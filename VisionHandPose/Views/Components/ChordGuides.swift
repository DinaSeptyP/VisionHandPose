//
//  ChordGuides.swift
//  VisionHandPose
//
//  Created by Muhamad Yuan Sastro Dimianta on 16/07/26.
//

import SwiftUI

import SwiftUI

struct ChordGuides: View {
    let chords = ["C","D","E","F","G","A","B"]
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
                        subtitle: "Use the hand you use to play chords on Chord Zone to form a note.",
                        titleSize: min(width * 0.07, 54),
                        numberSize: min(width * 0.15, 120),
                        iconSize: min(width * 0.045, 32),
                        subtitleSize: min(width * 0.03, 22)
                    )
                    .padding(.bottom)
                    
                    VStack (alignment: .leading) {
                        let columns1 = [
                            GridItem(.adaptive(minimum: 150, maximum: 220))
                        ]
                        
                        LazyVGrid(columns: columns1) {
                            ForEach(chords, id: \.self) { chord in
                                ChordCard(chord: chord)
                                    .padding(.horizontal, 5)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom)
                    
                    VStack (alignment: .leading) {
                        Text("Use the hand you use to strum on Strum Zone to form chord's type.")
                            .font(.custom("Inter", size: 23))
                            .fontWeight(.regular)
                            .foregroundStyle(Color("PrimaryBackground"))
                            .padding(.bottom)
                        
                        let columns2 = [
                            GridItem(.adaptive(minimum: 150, maximum: 220))
                        ]
                        
                        LazyVGrid(columns: columns2) {
                            ForEach(chordTypes, id: \.self) { chordTypes in
                                ChordCard(chord: chordTypes)
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
    ChordGuides()
}
