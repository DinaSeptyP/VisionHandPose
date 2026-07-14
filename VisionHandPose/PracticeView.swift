import SwiftUI

struct PracticeView: View {
    @ObservedObject var manager: HandPoseManager
    @ObservedObject var chordPlayer: ChordPlayer
    
    @State private var selectedChord: MusicalChord = .c
    @State private var activeStrings: [Bool] = [false, false, false, false, false, false]
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    private let availableChords: [MusicalChord] = [
        .c, .d, .e, .f, .g, .a, .b,
        .cSharp, .dSharp, .fSharp, .gSharp, .aSharp
    ]
    
    var body: some View {
        NavigationStack {
            Group {
                if horizontalSizeClass == .regular {
                    // iPad Split practice layout
                    HStack(spacing: 24) {
                        // Left Chord Selection Panel
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Chord Fingering Select")
                                .font(.headline)
                                .foregroundColor(.cyan)
                                .padding(.horizontal)
                            
                            ScrollView {
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                    ForEach(availableChords, id: \.self) { chord in
                                        Button(action: {
                                            selectedChord = chord
                                        }) {
                                            VStack(spacing: 4) {
                                                Text(chord.rawValue)
                                                    .font(.title3)
                                                    .fontWeight(.bold)
                                                Text(chord.fingerPattern.prefix(16) + "...")
                                                    .font(.system(size: 8))
                                                    .foregroundColor(.white.opacity(0.5))
                                            }
                                            .foregroundColor(selectedChord == chord ? .black : .white)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(selectedChord == chord ? Color.cyan : Color.white.opacity(0.06))
                                            .cornerRadius(12)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .frame(width: 270)
                        .background(Color.white.opacity(0.03))
                        .cornerRadius(20)
                        .padding(.vertical)
                        
                        // Right Large Strum Board
                        VStack(spacing: 20) {
                            chordDetailHeader
                            
                            Spacer()
                            
                            largeInteractiveFretboard
                            
                            Spacer()
                            
                            strumAllButton
                        }
                        .padding(.vertical)
                    }
                    .padding(.horizontal)
                } else {
                    // iPhone Vertical layout
                    ScrollView {
                        VStack(spacing: 20) {
                            // Chord select grid
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Chords")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white.opacity(0.6))
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        ForEach(availableChords, id: \.self) { chord in
                                            Button(action: { selectedChord = chord }) {
                                                Text(chord.rawValue)
                                                    .font(.headline)
                                                    .foregroundColor(selectedChord == chord ? .black : .white)
                                                    .padding(.horizontal, 20)
                                                    .padding(.vertical, 12)
                                                    .background(selectedChord == chord ? Color.cyan : Color.white.opacity(0.08))
                                                    .cornerRadius(12)
                                            }
                                        }
                                    }
                                }
                            }
                            
                            chordDetailHeader
                            
                            largeInteractiveFretboard
                            
                            strumAllButton
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Guitar Practice Board")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Subcomponents
    
    private var chordDetailHeader: some View {
        VStack(spacing: 6) {
            Text("Selected Chord Voicing")
                .font(.caption)
                .foregroundColor(.white.opacity(0.4))
            
            Text(selectedChord.rawValue)
                .font(.system(size: 40, weight: .black, design: .rounded))
                .foregroundColor(.cyan)
            
            Text(selectedChord.fingerPattern)
                .font(.footnote)
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.04))
        .cornerRadius(16)
    }
    
    private var largeInteractiveFretboard: some View {
        VStack(spacing: 12) {
            let stringNames = ["6th String (E)", "5th String (A)", "4th String (D)", "3rd String (G)", "2nd String (B)", "1st String (E)"]
            
            ForEach(0..<6) { i in
                let note = selectedChord.guitarStrings[i]
                
                Button(action: {
                    pluckString(at: i)
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(stringNames[i])
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                            
                            Text(note.isEmpty ? "Muted" : note)
                                .font(.system(size: 16, weight: .bold, design: .monospaced))
                                .foregroundColor(note.isEmpty ? .white.opacity(0.2) : .white)
                        }
                        
                        Spacer()
                        
                        // Pick simulator
                        Image(systemName: "music.quarternote.button")
                            .font(.title3)
                            .foregroundColor(activeStrings[i] ? .green : .cyan)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(activeStrings[i] ? Color.green.opacity(0.15) : Color.white.opacity(0.05))
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(activeStrings[i] ? Color.green.opacity(0.4) : Color.white.opacity(0.06), lineWidth: 1)
                    )
                }
            }
        }
    }
    
    private var strumAllButton: some View {
        Button(action: strumAll) {
            HStack {
                Image(systemName: "guitars.fill")
                Text("STRUM PLAY CHORD")
                    .fontWeight(.bold)
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(Color.cyan)
            .cornerRadius(18)
            .shadow(color: Color.cyan.opacity(0.3), radius: 8)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Actions
    
    private func pluckString(at index: Int) {
        let note = selectedChord.guitarStrings[index]
        guard !note.isEmpty else { return }
        
        chordPlayer.playNote(note)
        
        withAnimation(.easeInOut(duration: 0.1)) {
            activeStrings[index] = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation {
                activeStrings[index] = false
            }
        }
    }
    
    private func strumAll() {
        for i in 0..<6 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.045) {
                pluckString(at: i)
            }
        }
    }
}
