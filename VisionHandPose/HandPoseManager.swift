import Foundation
import AVFoundation
import Vision
import Combine
import SwiftUI
import UIKit

// MARK: - Models

struct HandJointPoint: Identifiable, Equatable {
    let id: String
    let location: CGPoint
    let confidence: Float
}

enum HandReadiness {
    case noHand
    case partial
    case tooFar
    case tooClose
    case ready

    var canReadChord: Bool {
        self == .ready
    }

    var statusMessage: String {
        switch self {
        case .noHand: return "No hands detected. Show your hand."
        case .partial: return "Hand partially visible. Keep your full hand in frame."
        case .tooFar: return "Move your hand closer."
        case .tooClose: return "Move your hand farther away."
        case .ready: return "Hand position ready."
        }
    }

    var indicatorColor: Color {
        switch self {
        case .noHand: return .cyan
        case .partial: return .orange
        case .tooFar: return .yellow
        case .tooClose: return .red
        case .ready: return .green
        }
    }
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

    // The 6-string voicing mapped to the string indices (0 = string 6, 5 = string 1)
    var guitarStrings: [String] {
        switch self {
        case .none:
            return ["", "", "", "", "", ""]
        case .a:
            return ["E3", "A3", "E", "A", "C#5", "E5"]
        case .aSharp:
            return ["F3", "A#3", "F", "A#", "D5", "F5"]
        case .b:
            return ["F#3", "B3", "F#", "B", "D#5", "F#5"]
        case .c:
            return ["E3", "C", "E", "G", "C5", "E5"]
        case .cSharp:
            return ["F3", "C#", "F", "G#", "C#5", "F5"]
        case .d:
            return ["D3", "A3", "D", "F#", "A", "D5"]
        case .dSharp:
            return ["D#3", "A#3", "D#", "G", "A#", "D#5"]
        case .e: // E Minor voicing
            return ["E3", "B3", "E", "G", "B", "E5"]
        case .f:
            return ["F3", "C", "F", "A", "C5", "F5"]
        case .fSharp:
            return ["F#3", "C#", "F#", "A#", "C#5", "F#5"]
        case .g:
            return ["G3", "B3", "D", "G", "B", "G5"]
        case .gSharp:
            return ["G#3", "C", "D#", "G#", "C5", "G#5"]
        }
    }
}

struct HandPose: Identifiable {
    let id = UUID()
    let joints: [VNHumanHandPoseObservation.JointName: HandJointPoint]
    let chord: MusicalChord
    let confidence: Float
    let isLeftHand: Bool
    let readiness: HandReadiness
    let isStrumHand: Bool

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

    // Guitar specific state
    @Published var activeChord: MusicalChord = .none
    @Published var isRightHanded: Bool = true // Left side = Chord, Right side = Strum
    @Published var chordHand: HandPose? = nil
    @Published var strumHand: HandPose? = nil

    // Combine event publisher for strumming triggers (main-thread safe)
    let stringPluckedSubject = PassthroughSubject<Int, Never>()

    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.visionhandpose.sessionQueue")
    private var videoOutput = AVCaptureVideoDataOutput()
    nonisolated(unsafe) private var handPoseRequest = VNDetectHumanHandPoseRequest()

    // Strum crossing detection variables (accessed only on serial video queue)
    private var lastStrumY: CGFloat? = nil
    private var lastTriggerTimes: [Int: Date] = [:]
    private let stringYPositions: [CGFloat] = [0.35, 0.41, 0.47, 0.53, 0.59, 0.65]
    private let debounceInterval: TimeInterval = 0.10 // 100ms debounce per string for fast play
    
    private var rotationCoordinator: AVCaptureDevice.RotationCoordinator?
    private var rotationObservation: NSKeyValueObservation?

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
            if session.isRunning {
                session.stopRunning()
            }

            session.beginConfiguration()
            session.inputs.forEach { self.session.removeInput($0) }
            session.outputs.forEach { self.session.removeOutput($0) }

            guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: activeCameraPosition) else {
                session.commitConfiguration()
                DispatchQueue.main.async { self.statusMessage = "No camera found." }
                return
            }

            do {
                let input = try AVCaptureDeviceInput(device: camera)
                guard session.canAddInput(input) else {
                    session.commitConfiguration()
                    DispatchQueue.main.async { self.statusMessage = "Cannot add camera input." }
                    return
                }
                session.addInput(input)

                guard session.canAddOutput(videoOutput) else {
                    session.commitConfiguration()
                    DispatchQueue.main.async { self.statusMessage = "Cannot add video output." }
                    return
                }
                session.addOutput(videoOutput)
                videoOutput.alwaysDiscardsLateVideoFrames = true
                videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "com.visionhandpose.videoQueue"))
                videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]

                if let connection = videoOutput.connection(with: .video) {
                    let coordinator = AVCaptureDevice.RotationCoordinator(device: camera, previewLayer: nil)
                    self.rotationCoordinator = coordinator
                    
                    self.rotationObservation = coordinator.observe(\.videoRotationAngleForHorizonLevelCapture, options: [.initial, .new]) { [weak self] coord, change in
                        guard let self = self else { return }
                        self.sessionQueue.async {
                            if let connection = self.videoOutput.connection(with: .video),
                               let angle = change.newValue {
                                if connection.isVideoRotationAngleSupported(angle) {
                                    connection.videoRotationAngle = angle
                                }
                            }
                        }
                    }
                    
                    if connection.isVideoMirroringSupported {
                        connection.isVideoMirrored = (self.activeCameraPosition == .front)
                    }
                }

                session.commitConfiguration()
                session.startRunning()
                DispatchQueue.main.async { self.statusMessage = "Tracking active. Show your hand." }
            } catch {
                session.commitConfiguration()
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

    func updateVideoOrientation() {
        sessionQueue.async { [weak self] in
            guard let self, let conn = videoOutput.connection(with: .video) else { return }
            self.configureVideoConnection(conn)
        }
    }

    private func configureVideoConnection(_ connection: AVCaptureConnection) {
        let angle: CGFloat
        if let coordinator = self.rotationCoordinator {
            angle = coordinator.videoRotationAngleForHorizonLevelCapture
        } else {
            angle = Self.fallbackVideoRotationAngle()
        }
        
        if connection.isVideoRotationAngleSupported(angle) {
            connection.videoRotationAngle = angle
        }

        if connection.isVideoMirroringSupported {
            connection.isVideoMirrored = (activeCameraPosition == .front)
        }
    }
    
    private static func fallbackVideoRotationAngle() -> CGFloat {
        let orientation = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?
            .interfaceOrientation ?? .portrait
        switch orientation {
        case .portrait: return 90
        case .portraitUpsideDown: return 270
        case .landscapeLeft: return 180
        case .landscapeRight: return 0
        default: return 90
        }
    }

    // MARK: - Video Sample Buffer Delegate

    nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        do {
            try handler.perform([handPoseRequest])
            
            let observations = handPoseRequest.results ?? []
            let rawHands = observations.map { processObservation($0) }
            
            // Separate hands into chord hand and strum hand based on X coordinate and isRightHanded configuration
            var cHand: HandPose? = nil
            var sHand: HandPose? = nil
            let rightHandedVal = self.isRightHanded // read main-actor property safely on BG thread (it's atomic/read-only in this context)
            
            for hand in rawHands {
                if let wrist = hand.joints[.wrist] {
                    // Right handed: Chord hand on Left (x < 0.5), Strum hand on Right (x >= 0.5)
                    // Left handed: Chord hand on Right (x >= 0.5), Strum hand on Left (x < 0.5)
                    let isStrumSide = rightHandedVal ? (wrist.location.x >= 0.5) : (wrist.location.x < 0.5)
                    if isStrumSide {
                        if sHand == nil { sHand = hand }
                    } else {
                        if cHand == nil { cHand = hand }
                    }
                }
            }
            
            // Classify chord from Chord Hand
            var detectedChord: MusicalChord = .none
            if let chordHand = cHand {
                if chordHand.readiness.canReadChord {
                    detectedChord = classifyChord(joints: chordHand.joints)
                }
            }
            
            // Process Strum Hand & check Y-crossings against strings
            if let strumHand = sHand, let indexTip = strumHand.joints[.indexTip] {
                let currentY = indexTip.location.y
                
                if let lastY = lastStrumY {
                    for i in 0..<stringYPositions.count {
                        let stringY = stringYPositions[i]
                        
                        // Crossed if lastY and currentY are on opposite sides of stringY
                        let crossed = (lastY - stringY) * (currentY - stringY) <= 0 && lastY != currentY
                        
                        if crossed {
                            let now = Date()
                            let lastTime = lastTriggerTimes[i] ?? Date.distantPast
                            if now.timeIntervalSince(lastTime) >= debounceInterval {
                                lastTriggerTimes[i] = now
                                
                                // Send crossing event to main thread
                                let index = i
                                Task { @MainActor in
                                    self.stringPluckedSubject.send(index)
                                }
                            }
                        }
                    }
                }
                lastStrumY = currentY
            } else {
                lastStrumY = nil
            }
            
            // Reconstruct final HandPose states with correct attributes
            let finalCHand = cHand.map {
                HandPose(
                    joints: $0.joints,
                    chord: detectedChord,
                    confidence: $0.confidence,
                    isLeftHand: $0.isLeftHand,
                    readiness: $0.readiness,
                    isStrumHand: false
                )
            }
            
            let finalSHand = sHand.map {
                HandPose(
                    joints: $0.joints,
                    chord: .none,
                    confidence: $0.confidence,
                    isLeftHand: $0.isLeftHand,
                    readiness: $0.readiness,
                    isStrumHand: true
                )
            }
            
            Task { @MainActor in
                self.chordHand = finalCHand
                self.strumHand = finalSHand
                self.activeChord = detectedChord
                
                var handsList: [HandPose] = []
                if let c = finalCHand { handsList.append(c) }
                if let s = finalSHand { handsList.append(s) }
                self.detectedHands = handsList
                
                // Status Messaging
                if finalCHand == nil && finalSHand == nil {
                    self.statusMessage = "No hands detected. Left side = Chord, Right side = Strum."
                } else if finalCHand != nil && finalSHand == nil {
                    self.statusMessage = "Chord hand active (\(detectedChord.rawValue)). Raise strum hand on right."
                } else if finalCHand == nil && finalSHand != nil {
                    self.statusMessage = "Strum hand active. Raise chord hand on left."
                } else {
                    self.statusMessage = "Guitar ready! Hold chord on left, strum strings on right."
                }
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

        let isLeftHand = observation.chirality == .left

        let readiness = evaluateReadiness(joints: joints)

        return HandPose(
            joints: joints,
            chord: .none, // Decided later in main loop
            confidence: observation.confidence,
            isLeftHand: isLeftHand,
            readiness: readiness,
            isStrumHand: false // Decided later
        )
    }

    private nonisolated func evaluateReadiness(joints: [VNHumanHandPoseObservation.JointName: HandJointPoint]) -> HandReadiness {
        guard !joints.isEmpty else { return .noHand }

        let points = joints.values.map(\.location)
        let minX = points.map(\.x).min() ?? 0
        let maxX = points.map(\.x).max() ?? 0
        let minY = points.map(\.y).min() ?? 0
        let maxY = points.map(\.y).max() ?? 0
        let width = maxX - minX
        let height = maxY - minY
        let maxDimension = max(width, height)
        let averageConfidence = joints.values.reduce(Float(0)) { $0 + $1.confidence } / Float(joints.count)

        if joints.count < 14 || averageConfidence < 0.45 {
            return .partial
        }

        if minX < 0.01 || maxX > 0.99 || minY < 0.01 || maxY > 0.99 {
            return .partial
        }

        if maxDimension < 0.20 {
            return .tooFar
        }

        if maxDimension > 0.80 {
            return .tooClose
        }

        return .ready
    }

    // MARK: - Chord Classification

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

