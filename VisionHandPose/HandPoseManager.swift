import Foundation
import AVFoundation
import Vision
import Combine
import SwiftUI

// MARK: - Models

struct HandJointPoint: Identifiable, Equatable {
    let id: String
    let location: CGPoint
    let confidence: Float
}

enum MusicalChord: String {
    case none   = "—"
    case a      = "A"
    case aSharp = "A#"
    case b      = "B"
    case c      = "C"
    case cSharp = "C#"
    case d      = "D"
    case dSharp = "D#"
    case e      = "E"
    case f      = "F"
    case fSharp = "F#"
    case g      = "G"
    case gSharp = "G#"

    var icon: String {
        switch self {
        case .none:   return "hand.raised.slash"
        case .a:      return "hand.fist.fill"
        case .aSharp: return "hand.wave.fill"
        case .b:      return "hands.sparkles.fill"
        case .c:      return "hand.point.up.left.fill"
        case .cSharp: return "hand.point.up.fill"
        case .d:      return "hand.victory.fill"
        case .dSharp: return "hand.raised.fingers.spread.fill"
        case .e:      return "hand.raised.fill"
        case .f:      return "hand.raised.fill"
        case .fSharp: return "hand.thumbsup.fill"
        case .g:      return "hand.raised.fill"
        case .gSharp: return "hand.raised.fill"
        }
    }

    // Finger pattern used to trigger this chord
    var fingerPattern: String {
        switch self {
        case .none:   return "No chord detected"
        case .a:      return "Thumb only — thumbs up"
        case .aSharp: return "Thumb + little finger — hang loose"
        case .b:      return "Thumb + index — L-shape"
        case .c:      return "Index finger only"
        case .cSharp: return "Index + little finger — devil horns"
        case .d:      return "Index + middle — peace sign"
        case .dSharp: return "Index + middle + ring"
        case .e:      return "Index + middle + ring + little"
        case .f:      return "Index + middle + ring + little — all except thumb"
        case .fSharp: return "Thumb + index + middle"
        case .g:      return "All five fingers — open hand"
        case .gSharp: return "Thumb + index + middle + little — all except ring"
        }
    }

    // Notes (as ChordPlayer note names) that make up the chord for this pose
    var notes: [String] {
        switch self {
        case .none:   return []
        case .a:      return ["A", "C#", "E"]
        case .aSharp: return ["A#", "D", "F"]
        case .b:      return ["B", "D", "F#"]
        case .c:      return ["C", "E", "G"]
        case .cSharp: return ["C#", "E", "G#"]
        case .d:      return ["D", "F#", "A"]
        case .dSharp: return ["D#", "G", "A#"]
        case .e:      return ["E", "G", "B"]
        case .f:      return ["F", "A", "C2"]
        case .fSharp: return ["F#", "A", "C#"]
        case .g:      return ["G", "B", "D"]
        case .gSharp: return ["G#", "C", "D#"]
        }
    }
}

struct HandPose: Identifiable {
    let id = UUID()
    let joints: [VNHumanHandPoseObservation.JointName: HandJointPoint]
    let chord: MusicalChord
    let confidence: Float
    let isLeftHand: Bool

    var skeletonLines: [[CGPoint]] {
        var lines: [[CGPoint]] = []

        let chains: [[VNHumanHandPoseObservation.JointName]] = [
            [.wrist, .thumbCMC, .thumbMP, .thumbIP, .thumbTip],
            [.wrist, .indexMCP, .indexPIP, .indexDIP, .indexTip],
            [.wrist, .middleMCP, .middlePIP, .middleDIP, .middleTip],
            [.wrist, .ringMCP, .ringPIP, .ringDIP, .ringTip],
            [.wrist, .littleMCP, .littlePIP, .littleDIP, .littleTip]
        ]

        for chain in chains {
            let pts = chain.compactMap { joints[$0].flatMap { $0.confidence > 0.3 ? $0.location : nil } }
            if pts.count > 1 { lines.append(pts) }
        }

        let palmLine = [VNHumanHandPoseObservation.JointName.thumbCMC, .indexMCP, .middleMCP, .ringMCP, .littleMCP]
            .compactMap { joints[$0].flatMap { $0.confidence > 0.3 ? $0.location : nil } }
        if palmLine.count > 1 { lines.append(palmLine) }

        return lines
    }
}

// MARK: - Hand Pose Manager

class HandPoseManager: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {

    @Published var detectedHands: [HandPose] = []
    @Published var cameraPermissionGranted: Bool = false
    @Published var statusMessage: String = "Initializing..."
    @Published var activeCameraPosition: AVCaptureDevice.Position = .front

    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.visionhandpose.sessionQueue")
    private var videoOutput = AVCaptureVideoDataOutput()
    nonisolated(unsafe) private var handPoseRequest = VNDetectHumanHandPoseRequest()

    override init() {
        super.init()
        handPoseRequest.maximumHandCount = 2
        handPoseRequest.revision = VNDetectHumanHandPoseRequestRevision1
    }

    // MARK: - Camera Setup

    func checkPermissionAndStart() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            cameraPermissionGranted = true
            startSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                guard let self else { return }
                DispatchQueue.main.async {
                    self.cameraPermissionGranted = granted
                    if granted { self.startSession() }
                    else { self.statusMessage = "Camera access denied. Enable it in Settings." }
                }
            }
        case .denied, .restricted:
            cameraPermissionGranted = false
            statusMessage = "Camera access denied."
        @unknown default:
            break
        }
    }

    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if session.isRunning { return }

            session.beginConfiguration()
            session.inputs.forEach { self.session.removeInput($0) }
            session.outputs.forEach { self.session.removeOutput($0) }

            guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: activeCameraPosition) else {
                DispatchQueue.main.async { self.statusMessage = "No camera found." }
                return
            }

            do {
                let input = try AVCaptureDeviceInput(device: camera)
                guard session.canAddInput(input) else {
                    DispatchQueue.main.async { self.statusMessage = "Cannot add camera input." }
                    return
                }
                session.addInput(input)

                guard session.canAddOutput(videoOutput) else {
                    DispatchQueue.main.async { self.statusMessage = "Cannot add video output." }
                    return
                }
                session.addOutput(videoOutput)
                videoOutput.alwaysDiscardsLateVideoFrames = true
                videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "com.visionhandpose.videoQueue"))
                videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]

                if let conn = videoOutput.connection(with: .video) {
                    conn.videoRotationAngle = 0.0
                    conn.isVideoMirrored = (activeCameraPosition == .front)
                }

                session.commitConfiguration()
                session.startRunning()
                DispatchQueue.main.async { self.statusMessage = "Tracking active. Show your hand." }
            } catch {
                DispatchQueue.main.async { self.statusMessage = "Camera setup failed: \(error.localizedDescription)" }
            }
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if session.isRunning { session.stopRunning() }
        }
    }

    func toggleCamera() {
        activeCameraPosition = (activeCameraPosition == .front) ? .back : .front
        startSession()
    }

    // MARK: - Video Sample Buffer Delegate

    nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        do {
            try handler.perform([handPoseRequest])
            let hands = (handPoseRequest.results ?? []).map { processObservation($0) }
            Task { @MainActor in
                self.detectedHands = hands
                self.statusMessage = hands.isEmpty ? "No hands detected. Show your hand." : "Tracking \(hands.count) hand(s)"
            }
        } catch {
            print("Vision error: \(error.localizedDescription)")
        }
    }

    // MARK: - Observation Processing

    private nonisolated func processObservation(_ observation: VNHumanHandPoseObservation) -> HandPose {
        var joints: [VNHumanHandPoseObservation.JointName: HandJointPoint] = [:]

        let allJoints: [VNHumanHandPoseObservation.JointName] = [
            .wrist,
            .thumbCMC, .thumbMP, .thumbIP, .thumbTip,
            .indexMCP, .indexPIP, .indexDIP, .indexTip,
            .middleMCP, .middlePIP, .middleDIP, .middleTip,
            .ringMCP, .ringPIP, .ringDIP, .ringTip,
            .littleMCP, .littlePIP, .littleDIP, .littleTip
        ]

        for key in allJoints {
            if let pt = try? observation.recognizedPoint(key), pt.confidence > 0.3 {
                joints[key] = HandJointPoint(
                    id: key.rawValue.rawValue,
                    location: CGPoint(x: pt.location.x, y: 1 - pt.location.y),
                    confidence: pt.confidence
                )
            }
        }

        var isLeftHand = false
        if let thumbMP = joints[.thumbMP], let littleMCP = joints[.littleMCP] {
            isLeftHand = thumbMP.location.x < littleMCP.location.x
        }

        return HandPose(
            joints: joints,
            chord: classifyChord(joints: joints),
            confidence: observation.confidence,
            isLeftHand: isLeftHand
        )
    }

    // MARK: - Chord Classification
    //
    // Each chord maps to a unique combination of extended fingers.
    // "Extended" means the fingertip is farther from its base knuckle than a threshold.
    //
    // (thumb, index, middle, ring, little)
    //  A      → (T,F,F,F,F)  — thumb
    //  A#     → (T,F,F,F,T)  — thumb + little (hang loose)
    //  B      → (T,T,F,F,F)  — thumb + index — L-shape
    //  C      → (F,T,F,F,F)  — index only
    //  C#     → (F,T,F,F,T)  — index + little — devil horns
    //  D      → (F,T,T,F,F)  — index + middle (peace)
    //  D#     → (F,T,T,F,T)  — index + middle + little
    //  E      → (F,T,T,T,F)  — index + middle + ring
    //  F      → (F,T,T,T,T)  — all except thumb
    //  F#     → (T,T,T,F,F)  — all except ring + little
    //  G      → (T,T,T,T,T)  — open hand — all five fingers
    //  G#     → (T,T,T,F,T)  — all except ring

    private nonisolated func classifyChord(joints: [VNHumanHandPoseObservation.JointName: HandJointPoint]) -> MusicalChord {
        guard
            let thumbTip  = joints[.thumbTip],
            let indexTip  = joints[.indexTip],
            let middleTip = joints[.middleTip],
            let ringTip   = joints[.ringTip],
            let littleTip = joints[.littleTip],
            let wrist     = joints[.wrist]
        else { return .none }

        let T = dist(thumbTip.location,  wrist.location)  > 0.15
        let I = dist(indexTip.location,  wrist.location)  > 0.15
        let M = dist(middleTip.location, wrist.location)  > 0.15
        let R = dist(ringTip.location,   wrist.location)  > 0.15
        let L = dist(littleTip.location, wrist.location)  > 0.15

        switch (T, I, M, R, L) {
        case (true, false, false, false, false): return .a
        case (true,  false, false, false, true):  return .aSharp
        case (true, true,  false, false, false):  return .b
        case (false, true,  false, false, false): return .c
        case (false,  true,  false, false, true): return .cSharp
        case (false, true,  true,  false, false): return .d
        case (false, true,  true,  false,  true): return .dSharp
        case (false, true,  true,  true,  false):  return .e
        case (false,  true,  true,  true,  true):  return .f
        case (true,  true,  true,  false,  false): return .fSharp
        case (true,  true,  true,  true, true): return .g
        case (true, true, true,  false,  true):  return .gSharp
        default: return .none
        }
    }

    private nonisolated func dist(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        hypot(a.x - b.x, a.y - b.y)
    }
}
