//
//  ChordPlayer.swift
//  VisionHandPose
//
//  Created by Muhamad Yuan Sastro Dimianta on 07/07/26.
//

import AVFoundation
import Combine

// Per-note mutable state shared between the main thread and the audio render thread.
// All properties are written by the main thread before `active` is set to true,
// so the render thread only races on `active` itself (a Bool write/read) — acceptable here.
private final class NoteState {
    let freq: Double
    var phase: Double = 0
    var cursor: Int = 0
    var totalFrames: Int = 0
    var attackFrames: Int = 0
    var active: Bool = false

    init(freq: Double) { self.freq = freq }
}

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
    private let sampleRate: Double = 44100
    private let baseAmplitude: Float = 0.5
    private let outputGain: Float = 6.0
    private var noteStates: [String: NoteState] = [:]

    // Note name to MIDI number mapping (octave 4)
    let noteMap: [String: UInt8] = [
        "C": 60, "C#": 61, "D": 62, "D#": 63, "E": 64,
        "F": 65, "F#": 66, "G": 67, "G#": 68,
        "A": 69, "A#": 70, "B": 71,
        "C2": 72   // C one octave above middle C
    ]

    init() {
        // .playAndRecord lets the engine coexist with AVCaptureSession;
        // .defaultToSpeaker routes output to the speaker instead of the earpiece.
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .mixWithOthers])
            try session.setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }

        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!
        let sr = sampleRate
        let amplitude = baseAmplitude * outputGain

        // Pre-allocate one oscillator node per note before the engine starts.
        // Never add or remove nodes while the engine is running — that's what caused the graph crash.
        for (name, midi) in noteMap {
            let freq = 440.0 * pow(2.0, (Double(midi) - 69.0) / 12.0)
            let state = NoteState(freq: freq)
            noteStates[name] = state

            let node = AVAudioSourceNode(format: format) { [state] _, _, frameCount, audioBufferList -> OSStatus in
                let ptr = UnsafeMutableAudioBufferListPointer(audioBufferList)
                let count = Int(frameCount)

                guard state.active else {
                    for buf in ptr {
                        memset(buf.mData, 0, count * MemoryLayout<Float>.size)
                    }
                    return noErr
                }

                for f in 0..<count {
                    let t = state.cursor + f
                    let env: Float
                    if t < state.attackFrames {
                        env = Float(t) / Float(max(state.attackFrames, 1))
                    } else if t < state.totalFrames {
                        env = 1.0 - Float(t - state.attackFrames) / Float(max(state.totalFrames - state.attackFrames, 1))
                    } else {
                        env = 0
                    }
                    let rawSample = Float(sin(state.phase)) * env * amplitude
                    let sample = Float(tanh(Double(rawSample)))
                    state.phase += 2.0 * Double.pi * freq / sr
                    if state.phase > 2.0 * Double.pi { state.phase -= 2.0 * Double.pi }
                    for buf in ptr {
                        buf.mData?.assumingMemoryBound(to: Float.self)[f] = sample
                    }
                }
                state.cursor += count
                if state.cursor >= state.totalFrames { state.active = false }

                return noErr
            }

            engine.attach(node)
            engine.connect(node, to: engine.mainMixerNode, format: format)
        }

        do {
            try engine.start()
        } catch {
            print("Failed to start engine: \(error)")
        }
    }

    func playNote(_ name: String, duration: TimeInterval = 1.5) {
        guard let state = noteStates[name] else { return }
        state.active = false
        state.phase = 0
        state.cursor = 0
        state.totalFrames = Int(sampleRate * duration)
        state.attackFrames = Int(sampleRate * 0.005)
        state.active = true
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

    func stopNote(_ name: String) {
        noteStates[name]?.active = false
    }

    func stopAllNotes() {
        noteStates.values.forEach { $0.active = false }
    }

    func playChord(_ notes: [String]) {
        stopAllNotes()
        notes.forEach { playNote($0) }
    }

    func stopChord(_ notes: [String]) {
        notes.forEach { stopNote($0) }
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
