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
    let noteMap: [String: UInt8] = [
        "C": 60,
        "C#": 61,
        "D": 62,
        "D#": 63,
        "E": 64,
        "F": 65,
        "F#": 66,
        "G": 67,
        "G#": 68,
        "A": 69,
        "A#": 70,
        "B": 71,
        "C2": 72   // C tinggi (satu oktaf di atas C awal)
    ]
    
    //    init() {
    //        engine.attach(sampler)
    //        engine.connect(sampler, to: engine.mainMixerNode, format: nil)
    //
    //        do {
    //            try engine.start()
    //        } catch {
    //            print("Gagal start engine: \(error)")
    //        }
    //    }
    
    
    
    
    
    
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
    
    
    
    // Mainin satu note
    func stopNote(_ name: String) {
        guard let midiNote = noteMap[name] else { return }
        sampler.stopNote(midiNote, onChannel: 0)
    }
    
    // Mainin chord (beberapa note sekaligus), misal ["C", "E", "G"]
    func playChord(_ notes: [String]) {
        for note in notes {
            playNote(note)
        }
    }
    
    func stopChord(_ notes: [String]) {
        for note in notes {
            stopNote(note)
        }
    }
    
    func playNote(_ name: String, duration: TimeInterval = 1.0) {
        guard let midiNote = noteMap[name] else { return }
        sampler.startNote(midiNote, withVelocity: 100, onChannel: 0)
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            self.sampler.stopNote(midiNote, onChannel: 0)
        }
    }
}
