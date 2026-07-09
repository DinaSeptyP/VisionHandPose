//
//  SwiftUIView.swift
//  VisionHandPose
//
//  Created by Dylan Amadeus on 09/07/26.
//

import SwiftUI

struct SwiftUIView: View {
    let openMidi = [40, 45, 50, 55, 59, 64]
    @StateObject private var chordPlayer = ChordPlayer()
    var body: some View {
        Text("Hello")
            .onAppear {
                if let chordNotes = chordPlayer.Chord(chord: "C", type: "maj7") {
                    print("--------")
                    for midi in openMidi {
                        if let fret = chordPlayer.findFret(openMidi: midi, chordNotes: chordNotes) {
                            print(fret)
                        }
                    }
                }
        }
    }
}

#Preview {
    SwiftUIView()
}
