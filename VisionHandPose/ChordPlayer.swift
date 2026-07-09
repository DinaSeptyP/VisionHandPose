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
}
