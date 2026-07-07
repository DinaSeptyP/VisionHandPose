import Foundation
import AVFoundation
import Vision
import Combine
import SwiftUI

// MARK: - Models

/// Represents a single joint's location and status
struct HandJointPoint: Identifiable, Equatable {
    let id: String
    let location: CGPoint
    let confidence: Float
}

/// The set of classified gestures using only Vision coordinates
enum DetectedGesture: String {
    case none = "None (No Gesture)"
    case pinchIndex = "Pinch Thumb + Index (Jempol + Telunjuk)"
    case pinchMiddle = "Pinch Thumb + Middle (Jempol + Jari Tengah)"
    case pinchRing = "Pinch Thumb + Ring (Jempol + Jari Manis)"
    case pinchPinky = "Pinch Thumb + Little (Jempol + Kelingking)"
    case fist = "Fist (Kepalan Tangan)"
    case openHand = "Open Hand (Tangan Terbuka)"
    case victory = "Victory / Peace (Jari V)"
    case thumbsUp = "Thumbs Up (Jempol ke Atas)"
    
    var icon: String {
        switch self {
        case .none: return "hand.raised.slash"
        case .pinchIndex: return "hand.point.up.left.fill"
        case .pinchMiddle: return "hand.point.up.fill"
        case .pinchRing: return "hand.point.right.fill"
        case .pinchPinky: return "hand.thumbsup.fill" // close enough
        case .fist: return "hand.fist.fill"
        case .openHand: return "hand.raised.fill"
        case .victory: return "hand.victory.fill"
        case .thumbsUp: return "hand.thumbsup.fill"
        }
    }
}

/// Holds all the recognized joints and classification for one hand
struct HandPose: Identifiable {
    let id = UUID()
    let joints: [VNHumanHandPoseObservation.JointName: HandJointPoint]
    let gesture: DetectedGesture
    let confidence: Float
    let isLeftHand: Bool // Determined by relative layout of joints
    
    /// Connective lines to draw the hand skeletal structure
    var skeletonLines: [[CGPoint]] {
        var lines: [[CGPoint]] = []
        
        // Define finger chains
        let thumbChain: [VNHumanHandPoseObservation.JointName] = [.wrist, .thumbCMC, .thumbMP, .thumbIP, .thumbTip]
        let indexChain: [VNHumanHandPoseObservation.JointName] = [.wrist, .indexMCP, .indexPIP, .indexDIP, .indexTip]
        let middleChain: [VNHumanHandPoseObservation.JointName] = [.wrist, .middleMCP, .middlePIP, .middleDIP, .middleTip]
        let ringChain: [VNHumanHandPoseObservation.JointName] = [.wrist, .ringMCP, .ringPIP, .ringDIP, .ringTip]
        let littleChain: [VNHumanHandPoseObservation.JointName] = [.wrist, .littleMCP, .littlePIP, .littleDIP, .littleTip]
        
        let chains = [thumbChain, indexChain, middleChain, ringChain, littleChain]
        
        for chain in chains {
            var currentLine: [CGPoint] = []
            for jointName in chain {
                if let joint = joints[jointName], joint.confidence > 0.3 {
                    currentLine.append(joint.location)
                }
            }
            if currentLine.count > 1 {
                lines.append(currentLine)
            }
        }
        
        // Connect MCPs together to form the palm base
        let mcps: [VNHumanHandPoseObservation.JointName] = [.thumbCMC, .indexMCP, .middleMCP, .ringMCP, .littleMCP]
        var palmLine: [CGPoint] = []
        for jointName in mcps {
            if let joint = joints[jointName], joint.confidence > 0.3 {
                palmLine.append(joint.location)
            }
        }
        if palmLine.count > 1 {
            lines.append(palmLine)
        }
        
        return lines
    }
}

// MARK: - Hand Pose Manager

class HandPoseManager: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    @Published var detectedHands: [HandPose] = []
    @Published var cameraPermissionGranted: Bool = false
    @Published var statusMessage: String = "Initializing..."
    @Published var activeCameraPosition: AVCaptureDevice.Position = .front
    @Published var targetHandCount: Int = 1
    
    // Capture session objects
    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.academy.visionhandpose.sessionQueue")
    private var videoOutput = AVCaptureVideoDataOutput()
    
    // Vision Hand Pose Request
    private var handPoseRequest = VNDetectHumanHandPoseRequest()
    
    override init() {
        super.init()
        setupVision()
    }
    
    private func setupVision() {
        // Configure hand pose request
        handPoseRequest.maximumHandCount = 2 // Detect up to 2 hands
        // We use Revision 1 as it is widely compatible and highly accurate
        handPoseRequest.revision = VNDetectHumanHandPoseRequestRevision1
    }
    
    // MARK: - Camera Setup
    
    func checkPermissionAndStart() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            self.cameraPermissionGranted = true
            self.startSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.cameraPermissionGranted = granted
                    if granted {
                        self.startSession()
                    } else {
                        self.statusMessage = "Camera access denied. Enable it in Settings."
                    }
                }
            }
        case .denied, .restricted:
            self.cameraPermissionGranted = false
            self.statusMessage = "Camera access denied/restricted."
        @unknown default:
            break
        }
    }
    
    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.session.isRunning { return }
            
            self.session.beginConfiguration()
            
            // Remove existing inputs/outputs
            self.session.inputs.forEach { self.session.removeInput($0) }
            self.session.outputs.forEach { self.session.removeOutput($0) }
            
            // Choose camera
            guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: self.activeCameraPosition) else {
                DispatchQueue.main.async {
                    self.statusMessage = "No camera found on this device."
                }
                return
            }
            
            do {
                let input = try AVCaptureDeviceInput(device: camera)
                if self.session.canAddInput(input) {
                    self.session.addInput(input)
                } else {
                    DispatchQueue.main.async {
                        self.statusMessage = "Cannot add camera input."
                    }
                    return
                }
                
                // Add Video Output
                if self.session.canAddOutput(self.videoOutput) {
                    self.session.addOutput(self.videoOutput)
                    self.videoOutput.alwaysDiscardsLateVideoFrames = true
                    self.videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "com.academy.visionhandpose.videoQueue"))
                    
                    // Set video settings
                    self.videoOutput.videoSettings = [
                        kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
                    ]
                } else {
                    DispatchQueue.main.async {
                        self.statusMessage = "Cannot add video output."
                    }
                    return
                }
                
                // Configure orientation
                if let connection = self.videoOutput.connection(with: .video) {
                    connection.videoOrientation = .portrait
                    connection.isVideoMirrored = (self.activeCameraPosition == .front)
                }
                
                self.session.commitConfiguration()
                self.session.startRunning()
                
                DispatchQueue.main.async {
                    self.statusMessage = "Tracking active. Place hand in view."
                }
            } catch {
                DispatchQueue.main.async {
                    self.statusMessage = "Camera setup failed: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.session.isRunning {
                self.session.stopRunning()
            }
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
            
            guard let observations = handPoseRequest.results else {
                Task { @MainActor in
                    self.detectedHands = []
                }
                return
            }
            
            var hands: [HandPose] = []
            
            for observation in observations {
                let pose = processObservation(observation)
                hands.append(pose)
            }
            
            Task { @MainActor in
                self.detectedHands = hands
                if hands.isEmpty {
                    self.statusMessage = "No hands detected. Show your hand."
                } else {
                    self.statusMessage = "Tracking \(hands.count) hand(s)"
                }
            }
            
        } catch {
            print("Vision error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Observation processing & Gesture Recognition
    
    private func processObservation(_ observation: VNHumanHandPoseObservation) -> HandPose {
        var jointsDict: [VNHumanHandPoseObservation.JointName: HandJointPoint] = [:]
        
        // Collect all recognized points (there are 21 joints)
        let jointKeys: [VNHumanHandPoseObservation.JointName] = [
            .wrist,
            .thumbCMC, .thumbMP, .thumbIP, .thumbTip,
            .indexMCP, .indexPIP, .indexDIP, .indexTip,
            .middleMCP, .middlePIP, .middleDIP, .middleTip,
            .ringMCP, .ringPIP, .ringDIP, .ringTip,
            .littleMCP, .littlePIP, .littleDIP, .littleTip
        ]
        
        for key in jointKeys {
            if let point = try? observation.recognizedPoint(key), point.confidence > 0.3 {
                // Normalize location to SwiftUI coordinate space (0..1)
                // Vision is y-up, bottom-left is origin. We convert to y-down, top-left is origin.
                let flippedLocation = CGPoint(x: point.location.x, y: 1 - point.location.y)
                jointsDict[key] = HandJointPoint(
                    id: key.rawValue.rawValue,
                    location: flippedLocation,
                    confidence: point.confidence
                )
            }
        }
        
        // Classify hand chirality (is it left or right hand?)
        // We can do this roughly by looking at the thumb MCP relative to pinky MCP and wrist
        var isLeftHand = false
        if let thumbMP = jointsDict[.thumbMP],
           let littleMCP = jointsDict[.littleMCP],
           let wrist = jointsDict[.wrist] {
            // For front-facing mirrored camera, if thumb is to the left of the little finger,
            // and wrist is below, we can approximate which hand it is.
            isLeftHand = thumbMP.location.x < littleMCP.location.x
        }
        
        // Recognize gestures
        let gesture = classifyGesture(joints: jointsDict)
        
        return HandPose(
            joints: jointsDict,
            gesture: gesture,
            confidence: observation.confidence,
            isLeftHand: isLeftHand
        )
    }
    
    /// Pure Vision-based Gesture Recognition
    private func classifyGesture(joints: [VNHumanHandPoseObservation.JointName: HandJointPoint]) -> DetectedGesture {
        
        // Retrieve necessary points and ensure they have good confidence
        guard let wrist = joints[.wrist], wrist.confidence > 0.3,
              let thumbTip = joints[.thumbTip], thumbTip.confidence > 0.3,
              let indexTip = joints[.indexTip], indexTip.confidence > 0.3,
              let middleTip = joints[.middleTip], middleTip.confidence > 0.3,
              let ringTip = joints[.ringTip], ringTip.confidence > 0.3,
              let littleTip = joints[.littleTip], littleTip.confidence > 0.3,
              
              // Base MCP joints (Knuckles)
              let indexMCP = joints[.indexMCP], indexMCP.confidence > 0.3,
              let middleMCP = joints[.middleMCP], middleMCP.confidence > 0.3,
              let ringMCP = joints[.ringMCP], ringMCP.confidence > 0.3,
              let littleMCP = joints[.littleMCP], littleMCP.confidence > 0.3
        else {
            return .none
        }
        
        // Helper distances
        let thumbToIndexDist = distance(from: thumbTip.location, to: indexTip.location)
        let thumbToMiddleDist = distance(from: thumbTip.location, to: middleTip.location)
        let thumbToRingDist = distance(from: thumbTip.location, to: ringTip.location)
        let thumbToLittleDist = distance(from: thumbTip.location, to: littleTip.location)
        
        // Finger curls (distance between tip and knuckle MCP)
        let indexCurl = distance(from: indexTip.location, to: indexMCP.location)
        let middleCurl = distance(from: middleTip.location, to: middleMCP.location)
        let ringCurl = distance(from: ringTip.location, to: ringMCP.location)
        let littleCurl = distance(from: littleTip.location, to: littleMCP.location)
        
        // Average length of an extended finger is around 0.12 - 0.20 (in normalized screen space)
        // If it is curled, the fingertip folds in towards the palm and becomes very close to its knuckle (MCP), typically < 0.06
        let isIndexExtended = indexCurl > 0.09
        let isMiddleExtended = middleCurl > 0.09
        let isRingExtended = ringCurl > 0.09
        let isLittleExtended = littleCurl > 0.09
        
        // Pinch thresholds (touching fingers)
        // In normalized coordinates, a pinch is usually very close, under 0.035
        let pinchThreshold: CGFloat = 0.045
        
        // 1. PINCH DETECTION
        // We find which finger is closest to the thumb tip
        let pinchDistances = [
            (DetectedGesture.pinchIndex, thumbToIndexDist),
            (DetectedGesture.pinchMiddle, thumbToMiddleDist),
            (DetectedGesture.pinchRing, thumbToRingDist),
            (DetectedGesture.pinchPinky, thumbToLittleDist)
        ]
        
        // Filter those under threshold
        let activePinches = pinchDistances.filter { $0.1 < pinchThreshold }
        
        // If there's an active pinch, return the closest one
        if let closestPinch = activePinches.min(by: { $0.1 < $1.1 }) {
            // Confirm the finger is actually touching and not just near
            // For example, if you pinch thumb + index, middle/ring/pinky are usually extended or at least index/thumb tips are very close
            return closestPinch.0
        }
        
        // 2. FIST DETECTION
        // All fingers are curled (very close to their knuckles)
        if !isIndexExtended && !isMiddleExtended && !isRingExtended && !isLittleExtended {
            // The thumb is also close to index MCP or middle MCP in a fist
            if let thumbMP = joints[.thumbMP], thumbMP.confidence > 0.3 {
                let thumbToPalm = distance(from: thumbTip.location, to: indexMCP.location)
                if thumbToPalm < 0.10 {
                    return .fist
                }
            }
        }
        
        // 3. THUMBS UP DETECTION
        // Thumb is extended and pointing up, other fingers are curled
        if !isIndexExtended && !isMiddleExtended && !isRingExtended && !isLittleExtended {
            if let thumbCMC = joints[.thumbCMC], thumbCMC.confidence > 0.3 {
                let thumbLength = distance(from: thumbTip.location, to: thumbCMC.location)
                let isThumbExtended = thumbLength > 0.08
                // For thumbs up, the y coordinate of tip should be lower (which means higher up on screen, since 0 is top)
                let isThumbPointingUp = thumbTip.location.y < thumbCMC.location.y
                if isThumbExtended && isThumbPointingUp {
                    return .thumbsUp
                }
            }
        }
        
        // 4. VICTORY SIGN (PEACE) DETECTION
        // Index and Middle are extended, Ring and Pinky are curled
        if isIndexExtended && isMiddleExtended && !isRingExtended && !isLittleExtended {
            // Ensure index and middle tips are somewhat separated
            let indexToMiddleDist = distance(from: indexTip.location, to: middleTip.location)
            if indexToMiddleDist > 0.04 {
                return .victory
            }
        }
        
        // 5. OPEN HAND DETECTION
        // All fingers extended
        if isIndexExtended && isMiddleExtended && isRingExtended && isLittleExtended {
            return .openHand
        }
        
        return .none
    }
    
    private func distance(from point1: CGPoint, to point2: CGPoint) -> CGFloat {
        return hypot(point1.x - point2.x, point1.y - point2.y)
    }
}

