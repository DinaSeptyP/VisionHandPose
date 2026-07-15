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
    case none = "—"
    case c = "C"
    case d = "D"
    case e = "E"
    case f = "F"
    case g = "G"
    case a = "A"
    case b = "B"

    var accidentalSuffix: String {
        ""
    }

    var icon: String {
        switch self {
        case .none: return "hand.raised.slash"
        case .c:    return "hand.point.up.left.fill"
        case .d:    return "hand.victory.fill"
        case .e:    return "hand.raised.fill"
        case .f:    return "hand.raised.fill"
        case .g:    return "hand.raised.fill"
        case .a:    return "hand.fist.fill"
        case .b:    return "hands.sparkles.fill"
        }
    }

    // Finger pattern used to trigger this chord
    var fingerPattern: String {
        switch self {
        case .none: return "No chord detected"
        case .c:    return "Index only"
        case .d:    return "Index + middle only"
        case .e:    return "Index + middle + ring only"
        case .f:    return "Index + middle + ring + little only"
        case .g:    return "All five fingers"
        case .a:    return "Thumb only"
        case .b:    return "Thumb + index only"
        }
    }

    // Notes (as ChordPlayer note names) that make up the chord for this pose
    var notes: [String] {
        switch self {
        case .none: return []
        case .c:    return ["C", "E", "G"]
        case .d:    return ["D", "F#", "A"]
        case .e:    return ["E", "G", "B"]
        case .f:    return ["F", "A", "C2"]
        case .g:    return ["G", "B", "D"]
        case .a:    return ["A", "C#", "E"]
        case .b:    return ["B", "D", "F#"]
        }
    }

    // The 6-string voicing mapped to the string indices (0 = string 6, 5 = string 1)
    var guitarStrings: [String] {
        voicing(for: .major)
    }

    /// Returns 6-string guitar voicing based on chord type.
    /// Each entry is a note name (e.g., "C", "E", "G") or empty string for muted strings.
    func voicing(for type: StrumChordType) -> [String] {
        switch (self, type) {
        // C chord variants
        case (.c, .major):
            return ["E3", "C", "E", "G", "C5", "E5"]
        case (.c, .major7):
            return ["E3", "C", "E", "G", "B", "C5"]
        case (.c, .minor):
            return ["E3", "C", "Eb", "G", "C5", "Eb5"]
        case (.c, .minor7):
            return ["E3", "C", "Eb", "G", "Bb", "Eb5"]
        // D chord variants
        case (.d, .major):
            return ["D3", "A3", "D", "F#", "A", "D5"]
        case (.d, .major7):
            return ["D3", "A3", "D", "F#", "A", "C#5"]
        case (.d, .minor):
            return ["D3", "A3", "D", "F", "A", "D5"]
        case (.d, .minor7):
            return ["D3", "A3", "D", "F", "C", "A"]
        // E chord variants
        case (.e, .major):
            return ["E3", "B3", "E", "G", "B", "E5"]
        case (.e, .major7):
            return ["E3", "B3", "E", "G", "D", "B"]
        case (.e, .minor):
            return ["E3", "B3", "E", "G", "B", "E5"]
        case (.e, .minor7):
            return ["E3", "B3", "E", "G", "D", "E5"]
        // F chord variants
        case (.f, .major):
            return ["F3", "C", "F", "A", "C5", "F5"]
        case (.f, .major7):
            return ["F3", "C", "F", "A", "E", "C5"]
        case (.f, .minor):
            return ["F3", "C", "F", "Ab", "C5", "Eb5"]
        case (.f, .minor7):
            return ["F3", "C", "F", "Ab", "Eb", "C5"]
        // G chord variants
        case (.g, .major):
            return ["G3", "B3", "D", "G", "B", "G5"]
        case (.g, .major7):
            return ["G3", "B3", "D", "F#", "A", "B"]
        case (.g, .minor7):
            return ["G3", "B3", "D", "F", "Eb", "B"]
        // A chord variants
        case (.a, .major):
            return ["E3", "A3", "E", "A", "C#5", "E5"]
        case (.a, .major7):
            return ["E3", "A3", "E", "G#", "A", "C#5"]
        case (.a, .minor):
            return ["E3", "A3", "E", "A", "C5", "E5"]
        case (.a, .minor7):
            return ["E3", "A3", "E", "G", "C", "A"]
        // B chord variants
        case (.b, .major):
            return ["F#3", "B3", "F#", "B", "D#5", "F#5"]
        case (.b, .major7):
            return ["F#3", "B3", "F#", "A#", "D#", "F#5"]
        case (.b, .minor):
            return ["F#3", "B3", "F#", "A", "D#5", "F#5"]
        case (.b, .minor7):
            return ["F#3", "B3", "F#", "A", "D", "F#5"]
        // none or unrecognized combinations
        default:
            return ["", "", "", "", "", ""]
        }
    }
}

// Accidental type based on vertical position
enum Accidental {
    case sharp   // Top of frame (y < 0.33)
    case natural // Middle of frame (0.33 <= y <= 0.66)
    case flat    // Bottom of frame (y > 0.66)

    var suffix: String {
        switch self {
        case .sharp:   return "#"
        case .natural: return ""
        case .flat:    return "♭"
        }
    }

    static func from(y: CGFloat) -> Accidental {
        if y < 0.33 {
            return .sharp
        } else if y > 0.66 {
            return .flat
        } else {
            return .natural
        }
    }
}

// Strum chord type based on hand pose
enum StrumChordType: String {
    case none = "—"
    case major7 = "Maj7"
    case major = "Maj"
    case minor7 = "Min7"
    case minor = "Min"

    var icon: String {
        switch self {
        case .none:    return "hand.raised.slash"
        case .major7:  return "hand.raised.fingers.spread.fill"
        case .major:   return "hand.point.up.fill"
        case .minor7:  return "rock"
        case .minor:   return "hand.point.down.fill"
        }
    }

    var fingerPattern: String {
        switch self {
        case .none:    return "No chord type detected"
        case .major:   return "Index only"
        case .minor7:  return "Thumb + index + little only"
        case .minor:   return "Little finger only"
        case .major7:  return "Thumb + index only"
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
    let strumChordType: StrumChordType?

    var fingerDistances: [String: CGFloat] = [:]

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
    @Published var activeAccidental: Accidental = .natural
    @Published var activeStrumType: StrumChordType = .none
    @Published var isRightHanded: Bool = true // Left side = Chord, Right side = Strum
    @Published var chordHand: HandPose? = nil
    @Published var strumHand: HandPose? = nil
    @Published private(set) var handDistanceWarning: String? = nil
    @Published private(set) var needsNeutralPose = false
    @Published private(set) var isStrumTypeLocked = false

    // Pose changes must remain consistent for several camera frames before
    // they replace the active result. This prevents one noisy frame from
    // changing C into B while the user is moving between poses.
    private var stableChord: MusicalChord = .none
    private var pendingChord: MusicalChord = .none
    private var pendingChordFrameCount = 0
    private var neutralFistFrameCount = 0
    private var missingChordHandFrameCount = 0
    private var chordChangeArmed = true
    private var stableStrumType: StrumChordType = .none
    private var pendingStrumType: StrumChordType = .none
    private var pendingStrumTypeFrameCount = 0

    // Combine event publisher for strumming triggers (main-thread safe)
    let stringPluckedSubject = PassthroughSubject<Int, Never>()

    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.visionhandpose.sessionQueue")
    private var videoOutput = AVCaptureVideoDataOutput()
    nonisolated(unsafe) private var handPoseRequest = VNDetectHumanHandPoseRequest()

    // Strum crossing detection variables (accessed only on serial video queue)
    // AVCapture invokes these only on its serial video queue.
    nonisolated(unsafe) private var lastPickPoint: CGPoint? = nil
    nonisolated(unsafe) private var isPinching = false
    nonisolated(unsafe) private var lastTriggerTimes: [Int: Date] = [:]
    nonisolated(unsafe) private var lastStrumPinchRatio: CGFloat? = nil
    private let stringYPositions: [CGFloat] = [0.35, 0.41, 0.47, 0.53, 0.59, 0.65]
    private let debounceInterval: TimeInterval = 0.07 // responsive repeated picking without double-trigger noise
    // A natural "pick" pinch often leaves a small visible gap on camera.
    // These wider hysteresis limits recognize it before its transitional
    // thumb/index shape can be mistaken for Maj7.
    private let pinchStartRatio: CGFloat = 0.62
    private let pinchReleaseRatio: CGFloat = 0.82
    nonisolated(unsafe) private var rightHandedForCapture = true
    
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
                        let shouldMirror = self.activeCameraPosition == .front
                        connection.isVideoMirrored = shouldMirror
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

    func toggleHandedness() {
        isRightHanded.toggle()
        rightHandedForCapture = isRightHanded
    }

    private func stabilizedChord(
        for candidate: MusicalChord,
        isNeutralFist: Bool,
        handVisible: Bool
    ) -> MusicalChord {
        guard handVisible else {
            missingChordHandFrameCount += 1
            if missingChordHandFrameCount >= 15 {
                stableChord = .none
                chordChangeArmed = true
                needsNeutralPose = false
            }
            return stableChord
        }
        missingChordHandFrameCount = 0

        if isNeutralFist {
            neutralFistFrameCount += 1
            if neutralFistFrameCount >= 3 {
                stableChord = .none
                pendingChord = .none
                pendingChordFrameCount = 0
                chordChangeArmed = true
                needsNeutralPose = false
            }
            return stableChord
        }
        neutralFistFrameCount = 0

        if candidate == stableChord {
            pendingChord = candidate
            pendingChordFrameCount = 0
            needsNeutralPose = false
            return stableChord
        }

        // Once a chord is active, another chord is ignored until a fist has
        // explicitly reset the state. Transitional finger positions can no
        // longer be interpreted as C, D, E, F, or G along the way.
        if stableChord != .none && !chordChangeArmed {
            needsNeutralPose = candidate != .none
            return stableChord
        }

        guard candidate != .none else { return stableChord }

        if candidate != pendingChord {
            pendingChord = candidate
            pendingChordFrameCount = 1
        } else {
            pendingChordFrameCount += 1
        }

        if pendingChordFrameCount >= 2 {
            stableChord = candidate
            chordChangeArmed = false
            pendingChordFrameCount = 0
            needsNeutralPose = false
        }
        return stableChord
    }

    private func distanceWarning(for hands: [HandPose]) -> String? {
        var hasPartialHand = false
        var hasTooFarHand = false

        for hand in hands {
            switch hand.readiness {
            case .tooClose:
                return "HAND TOO CLOSE • MOVE FARTHER"
            case .tooFar:
                hasTooFarHand = true
            case .partial:
                hasPartialHand = true
            case .noHand, .ready:
                break
            }
        }

        if hasTooFarHand { return "HAND TOO FAR • MOVE CLOSER" }
        if hasPartialHand { return "SHOW THE FULL HAND INSIDE CAMERA" }
        return nil
    }

    private func stabilizedStrumType(
        for candidate: StrumChordType,
        handVisible: Bool
    ) -> StrumChordType {
        guard handVisible else {
            // Losing the hand briefly must not discard the selected type.
            // It changes only when another valid strum pose is shown.
            return stableStrumType
        }

        if candidate == stableStrumType {
            pendingStrumType = candidate
            pendingStrumTypeFrameCount = 0
            return stableStrumType
        }

        // Keep the last valid type while pinching/moving, but cancel a pending
        // replacement. A new type must be continuously visible; transitional
        // Min7 -> pinch frames must not accumulate into a false Maj7 lock.
        guard candidate != .none else {
            pendingStrumType = .none
            pendingStrumTypeFrameCount = 0
            return stableStrumType
        }

        if candidate != pendingStrumType {
            pendingStrumType = candidate
            pendingStrumTypeFrameCount = 1
        } else {
            pendingStrumTypeFrameCount += 1
        }

        // Initial selection stays nearly instant. Replacing an existing type
        // needs a few consecutive frames so finger-folding transitions are
        // ignored while keeping the interaction responsive.
        let requiredFrames = stableStrumType == .none ? 2 : 3
        if pendingStrumTypeFrameCount >= requiredFrames {
            stableStrumType = candidate
            pendingStrumTypeFrameCount = 0
            isStrumTypeLocked = true
        }
        return stableStrumType
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
            let shouldMirror = activeCameraPosition == .front
            connection.isVideoMirrored = shouldMirror
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
            let isCaptureMirrored = connection.isVideoMirrored
            let rawHands = observations.map { processObservation($0, isCaptureMirrored: isCaptureMirrored) }
            
            // Normal mode: anatomical left hand selects the base chord and
            // anatomical right hand selects chord type/strums. Left-handed
            // mode swaps both roles without depending on screen position.
            var cHand: HandPose? = nil
            var sHand: HandPose? = nil
            let rightHandedVal = rightHandedForCapture
            
            for hand in rawHands {
                let isChordHand = rightHandedVal ? hand.isLeftHand : !hand.isLeftHand
                if isChordHand {
                    if cHand == nil { cHand = hand }
                } else {
                    if sHand == nil { sHand = hand }
                }
            }
            
            // Classify chord from Chord Hand
            var detectedChord: MusicalChord = .none
            var detectedNeutralFist = false
            var chordFingerDistances: [String: CGFloat] = [:]
            var chordHandCenterY: CGFloat? = nil
            if let chordHand = cHand {
                if chordHand.readiness.canReadChord {
                    detectedChord = classifyChord(
                        joints: chordHand.joints,
                        handCenterY: chordHand.joints[.middleMCP]?.location.y,
                        isLeftHand: chordHand.isLeftHand
                    )
                    detectedNeutralFist = isNeutralFist(joints: chordHand.joints)
                    chordFingerDistances = calculateFingerDistances(joints: chordHand.joints)
                    chordHandCenterY = chordHand.joints[.middleMCP]?.location.y
                }
            }

            // Classify strum chord type
            var detectedStrumType: StrumChordType? = nil
            var strumPoseIsSettled = false
            if let strumHand = sHand {
                detectedStrumType = classifyStrumType(joints: strumHand.joints)
            }
            
            // Treat thumb + index as a guitar pick. Distances are normalized
            // against palm width so the gesture works at different distances.
            // Separate close/release thresholds prevent camera noise from
            // rapidly toggling the pinch state.
            if let strumHand = sHand,
               strumHand.readiness.canReadChord,
               let thumbTip = strumHand.joints[.thumbTip],
               let indexTip = strumHand.joints[.indexTip],
               let indexMCP = strumHand.joints[.indexMCP],
               let littleMCP = strumHand.joints[.littleMCP] {
                let palmWidth = dist(indexMCP.location, littleMCP.location)
                let pinchDistance = dist(thumbTip.location, indexTip.location)
                let ratio = palmWidth > 0.0001 ? pinchDistance / palmWidth : .greatestFiniteMagnitude

                // A deliberate type pose settles before it is selected. While
                // moving from Min toward a pinch, this ratio drops quickly and
                // the temporary thumb+index silhouette must not count as Maj7.
                if let previousRatio = lastStrumPinchRatio {
                    strumPoseIsSettled = abs(ratio - previousRatio) < 0.08
                }
                lastStrumPinchRatio = ratio

                if isPinching {
                    if ratio > pinchReleaseRatio {
                        isPinching = false
                        lastPickPoint = nil
                    }
                } else if ratio < pinchStartRatio {
                    isPinching = true
                    // Start tracking here; forming a pinch must not pluck a
                    // string before the pick itself moves across that string.
                    lastPickPoint = CGPoint(
                        x: (thumbTip.location.x + indexTip.location.x) / 2,
                        y: (thumbTip.location.y + indexTip.location.y) / 2
                    )
                }

                if isPinching {
                    let currentPickPoint = CGPoint(
                        x: (thumbTip.location.x + indexTip.location.x) / 2,
                        y: (thumbTip.location.y + indexTip.location.y) / 2
                    )

                    if let previousPickPoint = lastPickPoint {
                        for i in 0..<stringYPositions.count {
                            let stringY = stringYPositions[i]

                            let crossed = (previousPickPoint.y - stringY)
                                * (currentPickPoint.y - stringY) <= 0
                                && previousPickPoint.y != currentPickPoint.y

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
                    lastPickPoint = currentPickPoint
                }
            } else {
                isPinching = false
                lastPickPoint = nil
                lastStrumPinchRatio = nil
            }

            // A pinch changes the apparent thumb/index pose. It is a playing
            // gesture, not a request to replace the locked strum type.
            if isPinching || !strumPoseIsSettled {
                detectedStrumType = nil
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
            
            let chordHandForUI = finalCHand
            let strumHandForUI = finalSHand
            let chordCandidate = detectedChord
            let neutralFistCandidate = detectedNeutralFist
            let strumTypeCandidate = detectedStrumType ?? .none
            let handCenterYForUI = chordHandCenterY

            Task { @MainActor in
                let displayedChord = self.stabilizedChord(
                    for: chordCandidate,
                    isNeutralFist: neutralFistCandidate,
                    handVisible: chordHandForUI != nil
                )
                let displayedStrumType = self.stabilizedStrumType(
                    for: strumTypeCandidate,
                    handVisible: strumHandForUI != nil
                )

                self.chordHand = chordHandForUI
                self.strumHand = strumHandForUI
                self.activeChord = displayedChord
                self.activeStrumType = displayedStrumType
                if let centerY = handCenterYForUI {
                    self.activeAccidental = Accidental.from(y: centerY)
                }

                var handsList: [HandPose] = []
                if let c = chordHandForUI { handsList.append(c) }
                if let s = strumHandForUI { handsList.append(s) }
                self.detectedHands = handsList
                self.handDistanceWarning = self.distanceWarning(for: handsList)

                // Status Messaging
                if self.needsNeutralPose {
                    self.statusMessage = "Make a fist to reset, then show the next chord."
                } else if chordHandForUI == nil && strumHandForUI == nil {
                    self.statusMessage = "No hands detected. Left side = Chord, Right side = Strum."
                } else if chordHandForUI != nil && strumHandForUI == nil {
                    self.statusMessage = "Chord hand active (\(displayedChord.rawValue)\(self.activeAccidental.suffix)). Raise strum hand on right."
                } else if chordHandForUI == nil && strumHandForUI != nil {
                    self.statusMessage = "Strum hand active. Raise chord hand on left."
                } else {
                    self.statusMessage = "Guitar ready! \(displayedChord.rawValue)\(self.activeAccidental.suffix) \(displayedStrumType.rawValue)"
                }
            }
            
        } catch {
            print("Vision error: \(error.localizedDescription)")
        }
    }

    // MARK: - Observation Processing

    private nonisolated func processObservation(
        _ observation: VNHumanHandPoseObservation,
        isCaptureMirrored: Bool
    ) -> HandPose {
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

        // Vision reads chirality from the delivered pixel buffer. The front
        // camera buffer is mirrored to match the preview, so compensate here
        // to retain the user's anatomical left/right hand identity.
        let visionDetectedLeft = observation.chirality == .left
        let isLeftHand = isCaptureMirrored ? !visionDetectedLeft : visionDetectedLeft

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

        if maxDimension < 0.18 {
            return .tooFar
        }

        if maxDimension > 0.72 {
            return .tooClose
        }

        return .ready
    }

    // MARK: - Chord Classification

    private nonisolated func isNeutralFist(
        joints: [VNHumanHandPoseObservation.JointName: HandJointPoint]
    ) -> Bool {
        guard
            let wrist = joints[.wrist],
            let thumbTip = joints[.thumbTip],
            let indexMCP = joints[.indexMCP],
            let middleMCP = joints[.middleMCP],
            let ringMCP = joints[.ringMCP],
            let littleMCP = joints[.littleMCP],
            let indexPIP = joints[.indexPIP], let indexTip = joints[.indexTip],
            let middlePIP = joints[.middlePIP], let middleTip = joints[.middleTip],
            let ringPIP = joints[.ringPIP], let ringTip = joints[.ringTip],
            let littlePIP = joints[.littlePIP], let littleTip = joints[.littleTip]
        else { return false }

        let palmWidth = dist(indexMCP.location, littleMCP.location)
        guard palmWidth > 0.0001 else { return false }

        func isCurled(_ pip: HandJointPoint, _ tip: HandJointPoint) -> Bool {
            dist(tip.location, wrist.location) < dist(pip.location, wrist.location) * 1.15
        }

        let thumbPalmDistance = [indexMCP, middleMCP, ringMCP, littleMCP]
            .map { dist(thumbTip.location, $0.location) }
            .min() ?? .greatestFiniteMagnitude
        let thumbCurled = thumbPalmDistance < palmWidth * 0.85
        return thumbCurled
            && isCurled(indexPIP, indexTip)
            && isCurled(middlePIP, middleTip)
            && isCurled(ringPIP, ringTip)
            && isCurled(littlePIP, littleTip)
    }

    private nonisolated func classifyChord(
        joints: [VNHumanHandPoseObservation.JointName: HandJointPoint],
        handCenterY: CGFloat?,
        isLeftHand: Bool
    ) -> MusicalChord {
        guard
            let thumbTip  = joints[.thumbTip],
            let indexTip  = joints[.indexTip],
            let middleTip = joints[.middleTip],
            let ringTip   = joints[.ringTip],
            let littleTip = joints[.littleTip],
            let thumbCMC  = joints[.thumbCMC],
            let thumbMP   = joints[.thumbMP],
            let thumbIP   = joints[.thumbIP],
            let indexMCP  = joints[.indexMCP],
            let indexPIP  = joints[.indexPIP],
            let indexDIP  = joints[.indexDIP],
            let middleMCP = joints[.middleMCP],
            let middlePIP = joints[.middlePIP],
            let middleDIP = joints[.middleDIP],
            let ringMCP   = joints[.ringMCP],
            let ringPIP   = joints[.ringPIP],
            let ringDIP   = joints[.ringDIP],
            let littleMCP = joints[.littleMCP],
            let littlePIP = joints[.littlePIP],
            let littleDIP = joints[.littleDIP]
        else { return .none }

        // Joint angle similarity (cosTheta) is 100% invariant to hand scale and finger lengths
        let T = isThumbExtended(
            cmc: thumbCMC,
            mp: thumbMP,
            ip: thumbIP,
            tip: thumbTip,
            indexMCP: indexMCP,
            middleMCP: middleMCP,
            ringMCP: ringMCP,
            littleMCP: littleMCP,
            useLeftHandCalibration: isLeftHand
        )
        // Keep thumb/index strict because they separate B from C. Vision's
        // confidence naturally drops toward the ring and little fingers, so
        // use progressively more tolerant extension thresholds for D/E/F/G.
        let I = isFingerExtended(
            mcp: indexMCP, pip: indexPIP, dip: indexDIP, tip: indexTip,
            pipThreshold: 0.65, dipThreshold: 0.28, travelMultiplier: 1.28
        )
        let M = isFingerExtended(
            mcp: middleMCP, pip: middlePIP, dip: middleDIP, tip: middleTip,
            pipThreshold: isLeftHand ? 0.34 : 0.45,
            dipThreshold: isLeftHand ? -0.02 : 0.10,
            travelMultiplier: isLeftHand ? 1.09 : 1.16
        )
        let R = isFingerExtended(
            mcp: ringMCP, pip: ringPIP, dip: ringDIP, tip: ringTip,
            pipThreshold: isLeftHand ? 0.14 : 0.25,
            dipThreshold: isLeftHand ? -0.24 : -0.12,
            travelMultiplier: isLeftHand ? 1.00 : 1.04
        )
        let L = isFingerExtended(
            mcp: littleMCP, pip: littlePIP, dip: littleDIP, tip: littleTip,
            pipThreshold: isLeftHand ? 0.12 : 0.22,
            dipThreshold: isLeftHand ? -0.28 : -0.18,
            travelMultiplier: isLeftHand ? 1.00 : 1.03
        )

        // Map finger pattern to base note (C=0 through B=6)
        let baseNote: MusicalChord
        switch (T, I, M, R, L) {
        case (false, true,  false, false, false): baseNote = .c  // Index only
        case (false, true,  true,  false, false): baseNote = .d  // Index + Middle
        case (false, true,  true,  true,  false): baseNote = .e  // Index + Middle + Ring
        case (true, false, false, false, false): baseNote = .a  // Thumb only
        case (false, true,  true,  true,  true): baseNote = .f  // Index + Middle + Ring + Little
        case (true,  true,  true,  true,  true): baseNote = .g  // All five
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
            let middleTip = joints[.middleTip],
            let ringTip   = joints[.ringTip],
            let littleTip = joints[.littleTip],
            let thumbCMC  = joints[.thumbCMC],
            let thumbMP   = joints[.thumbMP],
            let thumbIP   = joints[.thumbIP],
            let indexMCP  = joints[.indexMCP],
            let indexPIP  = joints[.indexPIP],
            let indexDIP  = joints[.indexDIP],
            let middleMCP = joints[.middleMCP],
            let middlePIP = joints[.middlePIP],
            let middleDIP = joints[.middleDIP],
            let ringMCP   = joints[.ringMCP],
            let ringPIP   = joints[.ringPIP],
            let ringDIP   = joints[.ringDIP],
            let littleMCP = joints[.littleMCP],
            let littlePIP = joints[.littlePIP],
            let littleDIP = joints[.littleDIP]
        else { return .none }

        let T = isThumbExtended(
            cmc: thumbCMC,
            mp: thumbMP,
            ip: thumbIP,
            tip: thumbTip,
            indexMCP: indexMCP,
            middleMCP: middleMCP,
            ringMCP: ringMCP,
            littleMCP: littleMCP,
            useLeftHandCalibration: false
        )
        let I = isFingerExtended(
            mcp: indexMCP, pip: indexPIP, dip: indexDIP, tip: indexTip,
            pipThreshold: 0.65, dipThreshold: 0.28, travelMultiplier: 1.28
        )
        let M = isFingerExtended(
            mcp: middleMCP, pip: middlePIP, dip: middleDIP, tip: middleTip,
            pipThreshold: 0.45, dipThreshold: 0.10, travelMultiplier: 1.16
        )
        let R = isFingerExtended(
            mcp: ringMCP, pip: ringPIP, dip: ringDIP, tip: ringTip,
            pipThreshold: 0.25, dipThreshold: -0.12, travelMultiplier: 1.04
        )
        let L = isFingerExtended(
            mcp: littleMCP, pip: littlePIP, dip: littleDIP, tip: littleTip,
            // The little finger is shorter and often appears slightly bent
            // from the camera angle even when intentionally raised for Min.
            pipThreshold: 0.12, dipThreshold: -0.28, travelMultiplier: 0.98
        )

        // For Min, the little finger is the meaningful signal. A relaxed
        // thumb can look extended from the side, so do not let thumb noise
        // reject Min as long as index, middle, and ring remain folded.
        if L && !I && !M && !R {
            return .minor
        }

        switch (T, I, M, R, L) {
        case (false, true,  false, false, false): return .major
        case (true,  true,  false, false, true):  return .minor7
        case (true,  true,  false, false, false): return .major7
        default: return .none
        }
    }

    private nonisolated func dist(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        hypot(a.x - b.x, a.y - b.y)
    }

    private nonisolated func isFingerExtended(
        mcp: HandJointPoint,
        pip: HandJointPoint,
        dip: HandJointPoint,
        tip: HandJointPoint,
        pipThreshold: CGFloat,
        dipThreshold: CGFloat,
        travelMultiplier: CGFloat
    ) -> Bool {
        let v1 = CGPoint(x: pip.location.x - mcp.location.x, y: pip.location.y - mcp.location.y)
        let v2 = CGPoint(x: dip.location.x - pip.location.x, y: dip.location.y - pip.location.y)
        let v3 = CGPoint(x: tip.location.x - dip.location.x, y: tip.location.y - dip.location.y)
        
        let magnitude1 = hypot(v1.x, v1.y)
        let magnitude2 = hypot(v2.x, v2.y)
        let magnitude3 = hypot(v3.x, v3.y)
        
        guard magnitude1 > 0.0001, magnitude2 > 0.0001, magnitude3 > 0.0001 else { return false }
        let pipStraightness = (v1.x * v2.x + v1.y * v2.y) / (magnitude1 * magnitude2)
        let dipStraightness = (v2.x * v3.x + v2.y * v3.y) / (magnitude2 * magnitude3)
        
        // Require a straight finger and ensure its tip extends farther from
        // the palm than the middle joint. The second condition rejects many
        // partially folded fingers that still form a nearly straight angle.
        let tipTravel = dist(mcp.location, tip.location)
        let jointTravel = dist(mcp.location, pip.location)
        return pipStraightness > pipThreshold
            && dipStraightness > dipThreshold
            && tipTravel > jointTravel * travelMultiplier
    }

    private nonisolated func isThumbExtended(
        cmc: HandJointPoint,
        mp: HandJointPoint,
        ip: HandJointPoint,
        tip: HandJointPoint,
        indexMCP: HandJointPoint,
        middleMCP: HandJointPoint,
        ringMCP: HandJointPoint,
        littleMCP: HandJointPoint,
        useLeftHandCalibration: Bool
    ) -> Bool {
        let palmWidth = dist(indexMCP.location, littleMCP.location)
        guard palmWidth > 0.0001 else { return false }

        let v1 = CGPoint(x: ip.location.x - mp.location.x, y: ip.location.y - mp.location.y)
        let v2 = CGPoint(x: tip.location.x - ip.location.x, y: tip.location.y - ip.location.y)
        let magnitude1 = hypot(v1.x, v1.y)
        let magnitude2 = hypot(v2.x, v2.y)
        guard magnitude1 > 0.0001, magnitude2 > 0.0001 else { return false }

        let cosTheta = (v1.x * v2.x + v1.y * v2.y) / (magnitude1 * magnitude2)
        let thumbLength = dist(cmc.location, tip.location)
        let separationFromPalm = dist(tip.location, indexMCP.location)

        if useLeftHandCalibration {
            let palmCenter = CGPoint(
                x: (indexMCP.location.x + middleMCP.location.x + ringMCP.location.x + littleMCP.location.x) / 4,
                y: (indexMCP.location.y + middleMCP.location.y + ringMCP.location.y + littleMCP.location.y) / 4
            )
            let distanceFromPalmCenter = dist(tip.location, palmCenter)

            // On the left hand, perspective makes the thumb-to-index distance
            // unstable. Palm-center distance separates a tucked F thumb from
            // an extended G/B thumb more consistently.
            return cosTheta > 0.48
                && thumbLength > palmWidth * 0.68
                && distanceFromPalmCenter > palmWidth * 0.72
        }

        // Normalizing against palm width keeps the same sensitivity when the
        // hand moves closer to or farther from the camera. Requiring both
        // length and palm separation prevents a tucked thumb from turning C
        // into B for a single frame.
        return cosTheta > 0.55
            && thumbLength > palmWidth * 0.72
            && separationFromPalm > palmWidth * 0.60
    }
}
