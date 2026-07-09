//
//  Tone Generator.swift
//  AVFoundationLearn
//
//  Created by Muhamad Yuan Sastro Dimianta on 07/07/26.
//

import AVFoundation
import Combine

class ChordPlayer: ObservableObject {
    private let engine = AVAudioEngine()
    private let sampler = AVAudioUnitSampler()
    
    // Mapping nama not ke MIDI note number (oktaf 4)
//    let noteMap: [String: UInt8] = [
//        "C": 60,
//        "C#": 61,
//        "D": 62,
//        "D#": 63,
//        "E": 64,
//        "F": 65,
//        "F#": 66,
//        "G": 67,
//        "G#": 68,
//        "A": 69,
//        "A#": 70,
//        "B": 71,
//        "C2": 72
//    ]
    
    let notes: [String] = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
//    let sixthString: [String: UInt8] = [
//        "E2": 40, "F2": 41, "F#2": 42, "G2": 43, "G#2": 44
//    ]
//    let fifthString: [String: UInt8] = [
//        "A2": 45, "A#2": 46, "B2": 47, "C3": 48, "C#3": 49
//    ]
//    let fourthString: [String: UInt8] = [
//        "D3": 50, "D#3": 51, "E3": 52, "F3": 53, "F#3": 54
//    ]
//    let thirdString: [String: UInt8] = [
//        "G3": 55, "G#3": 56, "A3": 57, "A#3": 58, "B3": 59
//    ]
//    let secondString: [String: UInt8] = [
//        "B3": 59, "C4": 60, "C#4": 61, "D4": 62, "D#4": 63
//    ]
//    let firstString: [String: UInt8] = [
//        "E4": 64, "F4": 65, "F#": 66, "G4": 67, "G#4": 68
//    ]
//    let noteMap: [String: UInt8] = sixthString.merge(fifthString).merge(fourthString).merge(thirdString).merge(secondString).merge(firstString)
    
//    let openMidi = [40, 45, 50, 55, 59, 64]
    
    init() {
        engine.attach(sampler)
        engine.connect(sampler, to: engine.mainMixerNode, format: nil)
        try? engine.start()
        loadGuitarSound()
    }
    
    private func loadGuitarSound() {
        do {
            // Program 24 = Acoustic Guitar (nylon) di General MIDI
            try sampler.loadSoundBankInstrument(
                at: defaultSoundBankURL(),
                program: 24,
                bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
                bankLSB: UInt8(kAUSampler_DefaultBankLSB)
            )
        } catch {
            print("Gagal load instrument gitar: \(error)")
        }
    }

    private func defaultSoundBankURL() -> URL {
        // Path ke sound bank bawaan Apple (ada di semua device iOS)
        URL(fileURLWithPath: "/System/Library/Components/CoreAudio.component/Contents/Resources/gs_instruments.dls")
    }
    
    func Chord(chord: String, type: String) -> [String]? {
        guard let chordArray = notes.firstIndex(of: chord) else {
            return nil
        }
       
        if (type == "maj") {
            return [notes[chordArray], notes[(chordArray+4)%12], notes[(chordArray+7)%12]]
        } else if (type == "min") {
            return [notes[chordArray], notes[(chordArray+3)%12], notes[(chordArray+7)%12]]
        } else if (type == "maj7") {
            return [notes[chordArray], notes[(chordArray+4)%12], notes[(chordArray+7)%12], notes[(chordArray+9)%12]]
        } else if (type == "min7") {
            return [notes[chordArray], notes[(chordArray+3)%12], notes[(chordArray+7)%12], notes[(chordArray+9)%12]]
        }
        return nil
    }
    
    func findFret(openMidi: Int, chordNotes: [String]) -> Int? {
        for fret in 0...20 {
            let midi = openMidi + fret
            let note = notes[midi % 12]

            if chordNotes.contains(note) {
                return fret
            }
        }
        return nil
    }
    
    // Mainin satu note
//    func stopNote(_ name: String) {
//        guard let midiNote = noteMap[name] else { return }
//        sampler.stopNote(midiNote, onChannel: 0)
//    }
//    
//    func playNote(_ name: String, duration: TimeInterval = 1.0) {
//        guard let midiNote = noteMap[name] else { return }
//        sampler.startNote(midiNote, withVelocity: 100, onChannel: 0)
//        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
//            self.sampler.stopNote(midiNote, onChannel: 0)
//        }
//    }
//    
//    // Mainin chord (beberapa note sekaligus), misal ["C", "E", "G"]
//    func playChord(_ notes: [String]) {
//        for note in notes {
//            playNote(note)
//        }
//    }
//    
//    func stopChord(_ notes: [String]) {
//        for note in notes {
//            stopNote(note)
//        }
//    }
}
