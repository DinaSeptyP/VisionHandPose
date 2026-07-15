import Foundation
import AVFoundation
import Vision
import Combine
import SwiftUI
import UIKit

// MARK: - Hand Pose Manager

class HandPoseManager: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {

    @Published var detectedHands: [HandPose] = []
    @Published var cameraPermissionGranted: Bool = false
    @Published var statusMessage: String = "Initializing..."
    @Published var activeCameraPosition: AVCaptureDevice.Position = .front

    // Guitar specific state
    @Published var activeChord: MusicalChord = .none
    @Published var activeAccidental: Accidental = .natural
    @Published var activeStrumType: StrumChordType = .major
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
            var chordFingerDistances: [String: CGFloat] = [:]
            var chordHandCenterY: CGFloat? = nil
            if let chordHand = cHand {
                if chordHand.readiness.canReadChord {
                    detectedChord = classifyChord(joints: chordHand.joints, handCenterY: chordHand.joints[.middleMCP]?.location.y)
                    chordFingerDistances = calculateFingerDistances(joints: chordHand.joints)
                    chordHandCenterY = chordHand.joints[.middleMCP]?.location.y
                }
            }

            // Classify strum chord type
            var detectedStrumType: StrumChordType? = nil
            if let strumHand = sHand {
                detectedStrumType = classifyStrumType(joints: strumHand.joints)
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
            var finalCHand: HandPose? = nil
            if let c = cHand {
                finalCHand = HandPose(
                    joints: c.joints,
                    chord: detectedChord,
                    confidence: c.confidence,
                    isLeftHand: c.isLeftHand,
                    readiness: c.readiness,
                    isStrumHand: false,
                    strumChordType: nil,
                    fingerDistances: chordFingerDistances
                )
            }

            var finalSHand: HandPose? = nil
            if let s = sHand {
                finalSHand = HandPose(
                    joints: s.joints,
                    chord: .none,
                    confidence: s.confidence,
                    isLeftHand: s.isLeftHand,
                    readiness: s.readiness,
                    isStrumHand: true,
                    strumChordType: detectedStrumType,
                    fingerDistances: [:]
                )
            }
            
            Task { @MainActor in
                self.chordHand = finalCHand
                self.strumHand = finalSHand
                self.activeChord = detectedChord
                self.activeStrumType = detectedStrumType ?? .major
                if let centerY = chordHandCenterY {
                    self.activeAccidental = Accidental.from(y: centerY)
                }

                var handsList: [HandPose] = []
                if let c = finalCHand { handsList.append(c) }
                if let s = finalSHand { handsList.append(s) }
                self.detectedHands = handsList

                // Status Messaging
                if finalCHand == nil && finalSHand == nil {
                    self.statusMessage = "No hands detected. Left side = Chord, Right side = Strum."
                } else if finalCHand != nil && finalSHand == nil {
                    self.statusMessage = "Chord hand active (\(detectedChord.rawValue)\(self.activeAccidental.suffix)). Raise strum hand on right."
                } else if finalCHand == nil && finalSHand != nil {
                    self.statusMessage = "Strum hand active. Raise chord hand on left."
                } else {
                    self.statusMessage = "Guitar ready! \(detectedChord.rawValue)\(self.activeAccidental.suffix) \(self.activeStrumType.rawValue)"
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
            isStrumHand: false, // Decided later
            strumChordType: nil,
            fingerDistances: [:]
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

    private nonisolated func classifyChord(joints: [VNHumanHandPoseObservation.JointName: HandJointPoint], handCenterY: CGFloat?) -> MusicalChord {
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

        // Map finger pattern to base note (C=0 through B=6)
        let baseNote: MusicalChord
        switch (T, I, M, R, L) {
        case (false, true,  false, false, false): baseNote = .c  // Index only
        case (false, true,  true,  false, false): baseNote = .d  // Index + Middle
        case (false, true,  true,  true,  false): baseNote = .e  // Index + Middle + Ring
        case (false, true,  true,  true,  true): baseNote = .f  // All except thumb
        case (true,  true,  true,  true,  true): baseNote = .g  // All five
        case (true,  false, false, false, false): baseNote = .a  // Thumb only
        case (true,  true,  false, false, false): baseNote = .b  // Thumb + Index
        default: return .none
        }

        // Apply accidental based on hand center Y position (middle of palm)
        let accidental = Accidental.from(y: handCenterY ?? 0.5)

        // For sharp zone, shift note up (e.g., C becomes C# = D♭)
        // For flat zone, shift note down conceptually, but we'll display as flat suffix
        switch accidental {
        case .sharp:
            return baseNote
        case .natural:
            return baseNote
        case .flat:
            return baseNote
        }
    }

    private nonisolated func calculateFingerDistances(joints: [VNHumanHandPoseObservation.JointName: HandJointPoint]) -> [String: CGFloat] {
        guard let wrist = joints[.wrist] else { return [:] }

        var distances: [String: CGFloat] = [:]

        if let thumbTip = joints[.thumbTip] {
            distances["thumb"] = dist(thumbTip.location, wrist.location)
        }
        if let indexTip = joints[.indexTip] {
            distances["index"] = dist(indexTip.location, wrist.location)
        }
        if let middleTip = joints[.middleTip] {
            distances["middle"] = dist(middleTip.location, wrist.location)
        }
        if let ringTip = joints[.ringTip] {
            distances["ring"] = dist(ringTip.location, wrist.location)
        }
        if let littleTip = joints[.littleTip] {
            distances["little"] = dist(littleTip.location, wrist.location)
        }

        return distances
    }

    private nonisolated func classifyStrumType(joints: [VNHumanHandPoseObservation.JointName: HandJointPoint]) -> StrumChordType {
        guard
            let thumbTip  = joints[.thumbTip],
            let indexTip  = joints[.indexTip],
            let littleTip = joints[.littleTip],
            let wrist     = joints[.wrist]
        else { return .major }

        let T = dist(thumbTip.location,  wrist.location) > 0.15
        let I = dist(indexTip.location,  wrist.location) > 0.15
        let L = dist(littleTip.location, wrist.location) > 0.15

        switch (T, I, L) {
        case (true,  true,  false): return .major7   // Thumb + Index (loose)
        case (false, true,  false): return .major    // Index pointing
        case (true,  true,  true):  return .minor7   // Thumb + Index + Pinky (rock)
        case (false, false, true):   return .minor    // Pinky only
        default: return .major
        }
    }

    private nonisolated func dist(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        hypot(a.x - b.x, a.y - b.y)
    }
}

