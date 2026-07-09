//
//  AudioSynthesizePreview.swift
//  VisionHandPose
//
//  Created by Muhamad Yuan Sastro Dimianta on 07/07/26.
//

import SwiftUI

struct AudioSynthesizePreview: View {
    @StateObject private var chordPlayer = ChordPlayer()
    let notes = ["C", "D", "E", "F", "G", "A", "B", "C2"]
    
    var body: some View {
        VStack {
            HStack {
                ForEach(notes, id: \.self) { note in
                    Button(note) {
                        chordPlayer.playNote(note)
                    }
                    .padding()
                    .background(Color.pink.opacity(0.3))
                    .clipShape(Circle())
                }
            }
            
            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]){
                    
                    Button("CMaj7") {
                        chordPlayer.playChord(["C", "E", "G", "B"])
                    }
                    .frame(width: 80, height: 80)
                    .background(Color.blue.opacity(0.3))
                    .clipShape(Circle())
                    
                    Button("CMaj") {
                        chordPlayer.playChord(["C", "E", "G"])
                    }
                    .frame(width: 80, height: 80)
                    .background(Color.blue.opacity(0.3))
                    .clipShape(Circle())
                    
                    Button("G on B") {
                        chordPlayer.playChord(["B", "D", "F"])
                    }
                    .frame(width: 80, height: 80)
                    .background(Color.blue.opacity(0.3))
                    .clipShape(Circle())
                    
                    Button("E7") {
                        chordPlayer.playChord(["E", "G#", "B", "D"])
                    }
                    .frame(width: 80, height: 80)
                    .background(Color.blue.opacity(0.3))
                    .clipShape(Circle())
                    
                    Button("Amin7") {
                        chordPlayer.playChord(["A", "C", "E", "G"])
                    }
                    .frame(width: 80, height: 80)
                    .background(Color.blue.opacity(0.3))
                    .clipShape(Circle())
                    
                    Button("Gmin") {
                        chordPlayer.playChord(["A#", "D", "F", "G"])
                    }
                    .frame(width: 80, height: 80)
                    .background(Color.blue.opacity(0.3))
                    .clipShape(Circle())
                    
                    Button("Fmaj7") {
                        chordPlayer.playChord(["F", "A", "C", "G"])
                    }
                    .frame(width: 80, height: 80)
                    .background(Color.blue.opacity(0.3))
                    .clipShape(Circle())
                    
                    Button("E on C") {
                        chordPlayer.playChord(["E", "G", "B"])
                    }
                    .frame(width: 80, height: 80)
                    .background(Color.blue.opacity(0.3))
                    .clipShape(Circle())
                    
                    Button("Dmaj") {
                        chordPlayer.playChord(["D", "F#", "A"])
                    }
                    .frame(width: 80, height: 80)
                    .background(Color.blue.opacity(0.3))
                    .clipShape(Circle())
                    
                    Button("Dmin") {
                        chordPlayer.playChord(["D", "F", "A"])
                    }
                    .frame(width: 80, height: 80)
                    .background(Color.blue.opacity(0.3))
                    .clipShape(Circle())
                    
                    Button("Gmaj7") {
                        chordPlayer.playChord(["G", "B", "D", "F"])
                    }
                    .frame(width: 80, height: 80)
                    .background(Color.blue.opacity(0.3))
                    .clipShape(Circle())
                    
                    
                }
            
        }
    }
}

#Preview {
    AudioSynthesizePreview()
}
