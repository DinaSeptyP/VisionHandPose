import SwiftUI
import Vision

struct LandmarksView: View {
    @ObservedObject var manager: HandPoseManager
    @State private var selectedJointGroup: String = "Thumb"
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    // Group mappings
    private let jointGroups = ["Thumb", "Index", "Middle", "Ring", "Pinky", "Wrist"]
    
    var body: some View {
        NavigationStack {
            Group {
                if horizontalSizeClass == .regular {
                    // iPad split layout
                    HStack(spacing: 24) {
                        // Left: Interactive Landmark Diagram / Live tracker
                        VStack(spacing: 16) {
                            Text("Live Coordinate Tracker")
                                .font(.headline)
                                .foregroundColor(.cyan)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            liveLandmarksCanvas
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color.black.opacity(0.3))
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                )
                        }
                        .padding(.vertical)
                        
                        // Right: Info Table
                        VStack(spacing: 16) {
                            Picker("Joint Groups", selection: $selectedJointGroup) {
                                ForEach(jointGroups, id: \.self) { group in
                                    Text(group).tag(group)
                                }
                            }
                            .pickerStyle(.segmented)
                            
                            ScrollView {
                                jointsTableForSelectedGroup
                            }
                        }
                        .frame(width: 290)
                        .padding(.vertical)
                    }
                    .padding(.horizontal, 24)
                } else {
                    // iPhone Stack Layout
                    ScrollView {
                        VStack(spacing: 20) {
                            Text("Live Coordinate Tracker")
                                .font(.headline)
                                .foregroundColor(.cyan)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            liveLandmarksCanvas
                                .frame(height: 320)
                                .background(Color.black.opacity(0.3))
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                )
                            
                            Picker("Joint Groups", selection: $selectedJointGroup) {
                                ForEach(jointGroups, id: \.self) { group in
                                    Text(group).tag(group)
                                }
                            }
                            .pickerStyle(.segmented)
                            
                            jointsTableForSelectedGroup
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Vision Landmark Analyzer")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Live Tracker Canvas
    
    private var liveLandmarksCanvas: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            
            if let hand = manager.detectedHands.first {
                ZStack {
                    // Draw lines
                    Path { path in
                        for line in hand.skeletonLines {
                            guard let first = line.first else { continue }
                            path.move(to: CGPoint(x: first.x * w, y: first.y * h))
                            for pt in line.dropFirst() {
                                path.addLine(to: CGPoint(x: pt.x * w, y: pt.y * h))
                            }
                        }
                    }
                    .stroke(Color.cyan.opacity(0.6), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    
                    // Draw joint dots with names
                    ForEach(Array(hand.joints.keys), id: \.self) { key in
                        if let joint = hand.joints[key] {
                            let isSelectedGroupJoint = checkIfJointMatchesGroup(key: key, groupName: selectedJointGroup)
                            
                            Circle()
                                .fill(isSelectedGroupJoint ? Color.green : Color.cyan)
                                .frame(width: isSelectedGroupJoint ? 12 : 8, height: isSelectedGroupJoint ? 12 : 8)
                                .shadow(color: isSelectedGroupJoint ? .green : .cyan, radius: 4)
                                .position(x: joint.location.x * w, y: joint.location.y * h)
                            
                            if isSelectedGroupJoint {
                                Text(getShortJointName(key))
                                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .background(Color.green)
                                    .cornerRadius(3)
                                    .position(x: joint.location.x * w, y: joint.location.y * h - 14)
                            }
                        }
                    }
                }
            } else {
                VStack {
                    Spacer()
                    Image(systemName: "hand.raised.fill")
                        .font(.largeTitle)
                        .foregroundColor(.white.opacity(0.15))
                        .padding(.bottom, 8)
                    Text("No hand detected. Raise hand in camera (Air Guitar tab) to see live landmarks.")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.4))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    // MARK: - Joints Table
    
    private var jointsTableForSelectedGroup: some View {
        VStack(spacing: 12) {
            let jointsList = getJointsForGroup(groupName: selectedJointGroup)
            let hand = manager.detectedHands.first
            
            ForEach(jointsList, id: \.self) { jointName in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(getShortJointName(jointName))
                            .font(.system(.subheadline, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Apple API Key: \(jointName.rawValue.rawValue)")
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    
                    Spacer()
                    
                    if let hand = hand, let jointPoint = hand.joints[jointName] {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(String(format: "X: %.3f, Y: %.3f", jointPoint.location.x, jointPoint.location.y))
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundColor(.green)
                            
                            Text(String(format: "Conf: %.0f%%", jointPoint.confidence * 100))
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    } else {
                        Text("Not Tracked")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.2))
                    }
                }
                .padding()
                .background(Color.white.opacity(0.04))
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Helpers
    
    private func getJointsForGroup(groupName: String) -> [VNHumanHandPoseObservation.JointName] {
        switch groupName {
        case "Thumb":
            return [.thumbCMC, .thumbMP, .thumbIP, .thumbTip]
        case "Index":
            return [.indexMCP, .indexPIP, .indexDIP, .indexTip]
        case "Middle":
            return [.middleMCP, .middlePIP, .middleDIP, .middleTip]
        case "Ring":
            return [.ringMCP, .ringPIP, .ringDIP, .ringTip]
        case "Pinky":
            return [.littleMCP, .littlePIP, .littleDIP, .littleTip]
        case "Wrist":
            return [.wrist]
        default:
            return []
        }
    }
    
    private func checkIfJointMatchesGroup(key: VNHumanHandPoseObservation.JointName, groupName: String) -> Bool {
        return getJointsForGroup(groupName: groupName).contains(key)
    }
    
    private func getShortJointName(_ joint: VNHumanHandPoseObservation.JointName) -> String {
        switch joint {
        case .wrist: return "Wrist"
        case .thumbCMC: return "Thumb CMC"
        case .thumbMP: return "Thumb MP"
        case .thumbIP: return "Thumb IP"
        case .thumbTip: return "Thumb TIP"
        case .indexMCP: return "Index MCP"
        case .indexPIP: return "Index PIP"
        case .indexDIP: return "Index DIP"
        case .indexTip: return "Index TIP"
        case .middleMCP: return "Middle MCP"
        case .middlePIP: return "Middle PIP"
        case .middleDIP: return "Middle DIP"
        case .middleTip: return "Middle TIP"
        case .ringMCP: return "Ring MCP"
        case .ringPIP: return "Ring PIP"
        case .ringDIP: return "Ring DIP"
        case .ringTip: return "Ring TIP"
        case .littleMCP: return "Pinky MCP"
        case .littlePIP: return "Pinky PIP"
        case .littleDIP: return "Pinky DIP"
        case .littleTip: return "Pinky TIP"
        default: return "Unknown"
        }
    }
}
