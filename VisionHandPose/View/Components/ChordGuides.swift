//
//  ChordGuides.swift
//  VisionHandPose
//
//  Created by Dylan Amadeus on 15/07/26.
//

import SwiftUI

struct ChordGuides: View {
    let chords = ["C","D","E","F","G","A","B"]
    let chordTypes = ["Major","Minor","Major7","Minor7"]
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading) {
                VStack(alignment: .leading) {
                    Text("03")
                        .font(.custom("Playfair Display", size: 180))
                        .fontWeight(.black)
                        .foregroundStyle(Color("PrimaryBrown").opacity(0.2))
                    Text("\(Image(systemName: "music.pages"))")
                        .font(.custom("Playfair Display", size: 40))
                        .foregroundStyle(Color("PrimaryFont"))
                        .padding(25)
                        .background(Color("SecondaryFont").opacity(0.9))
                        .cornerRadius(20)
                        .padding(.top, -220)
                }
                .padding(.bottom, -100)
                
                Text("Chord Guides")
                    .font(.custom("Playfair Display", size: 60))
                    .fontWeight(.black)
                    .foregroundStyle(Color("PrimaryBackground"))
                    .lineLimit(2)
                    .padding(.bottom)
                
                Text("Use the hand you use to play chords on Chord Zone to form a note.")
                    .font(.custom("Inter", size: 23))
                    .fontWeight(.regular)
                    .foregroundStyle(Color("PrimaryBackground"))
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
                
                HStack {
                    Text("\(Image(systemName: "lightbulb.max"))")
                        .font(.custom("Inter", size: 20))
                        .foregroundStyle(Color("SecondaryFont"))
                    Text("Tip: Greater Camera View, Easy Chord Recognition")
                        .font(.custom("Inter", size: 20))
                        .fontWeight(.light)
                        .foregroundStyle(Color("PrimaryBrown"))
                }
                .padding()
                .background(Color("SecondaryFont").opacity(0.1))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color("SecondaryFont"), lineWidth: 0.5)
                )
                .padding(.bottom, 100)
            }
            .padding()
            .padding(.top, -50)
        }
        
    }
}

#Preview {
    ChordGuides()
}
