import AVFoundation
import Combine

// Per-note mutable state shared between the main thread and the audio render thread.
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
    private let baseAmplitude: Float = 0.35
    private let outputGain: Float = 6.0
    private var noteStates: [String: NoteState] = [:]

    // Note name to MIDI number mapping covering multiple octaves for realistic guitar voicing
//    let noteMap: [String: UInt8] = [
//        // Octave 3 (Low / Bass strings)
//        "C3": 48, "C#3": 49, "D3": 50, "D#3": 51, "E3": 52, "F3": 53, "F#3": 54, "G3": 55, "G#3": 56, "A3": 57, "A#3": 58, "B3": 59,
//        // Octave 4 (Middle strings)
//        "C": 60, "C#": 61, "D": 62, "D#": 63, "Eb": 63, "E": 64, "F": 65, "F#": 66, "G": 67, "G#": 68, "Ab": 68, "A": 69, "A#": 70, "Bb": 70, "B": 71,
//        // Octave 5 (High strings)
//        "C5": 72, "C#5": 73, "D5": 74, "D#5": 75, "Eb5": 75, "E5": 76, "F5": 77, "F#5": 78, "G5": 79, "G#5": 80, "A5": 81, "A#5": 82, "Bb5": 82, "B5": 83,
//        // Compatibility
//        "C2": 72
//    ]
    
    //ganti dylan
    let noteMap: [String: UInt8] = [
        // String 6
        "E3": 52, "F3": 53, "F#3": 54, "G3": 55, "G#3": 56,

        // String 5
        "A3": 57, "A#3": 58, "B3": 59, "C4": 60, "C#4": 61,

        // String 4
        "D4": 62, "D#4": 63, "E4": 64, "F4": 65, "F#4": 66,

        // String 3
        "G4": 67, "G#4": 68, "A4": 69, "A#4": 70,

        // String 2
        "B4": 71, "C5": 72, "C#5": 73, "D5": 74, "D#5": 75,

        // String 1
        "E5": 76, "F5": 77, "F#5": 78, "G5": 79, "G#5": 80
    ]

    init() {
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

                    // Envelope as Double
                    let env: Double
                    if t < state.attackFrames {
                        env = Double(t) / Double(max(state.attackFrames, 1))
                    } else {
                        env = 1.0
                    }

                    let elapsed = Double(t - state.attackFrames)
                    let total = Double(max(state.totalFrames - state.attackFrames, 1))

                    // Acoustic Physical Modelling (Double precision)
                    let envFund = exp(-2.8 * elapsed / total)
                    let envHarm = exp(-8.5 * elapsed / total)

                    let phase = state.phase
                    let primary = sin(phase) * envFund
                    let harm1 = 0.35 * sin(2.0 * phase) * envHarm  // 2nd Harmonic (Octave)
                    let harm2 = 0.15 * sin(3.0 * phase) * envHarm  // 3rd Harmonic (Fifth)

                    // Sharp transient noise at the initial pluck (decays in 15ms)
                    let noiseDecay = exp(-elapsed / (sr * 0.015))
                    let pluckNoise = Double(Float.random(in: -0.06...0.06)) * noiseDecay

                    // Warm soft-clipping using tanh
                    let rawSample = (primary + harm1 + harm2) * env * Double(amplitude) + pluckNoise * env
                    let sample = Float(tanh(rawSample))

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

    func playNote(_ name: String, duration: TimeInterval = 1.8) {
        guard let state = noteStates[name] else { return }
        state.active = false
        state.phase = 0
        state.cursor = 0
        state.totalFrames = Int(sampleRate * duration)
        state.attackFrames = Int(sampleRate * 0.003) // ultra-sharp attack for pluck
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
