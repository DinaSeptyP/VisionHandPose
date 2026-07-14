//
//  drawHandSkeleton.swift
//  VisionHandPose
//
//  Created by Dylan Amadeus on 14/07/26.
//

import Foundation
import SwiftUI

func drawHandSkeleton(_ hand: HandPose, width: CGFloat, height: CGFloat, color: Color) -> some View {
    Group {
        Path { path in
            for line in hand.skeletonLines {
                guard let first = line.first else { continue }
                path.move(to: CGPoint(x: first.x * width, y: first.y * height))
                for pt in line.dropFirst() {
                    path.addLine(to: CGPoint(x: pt.x * width, y: pt.y * height))
                }
            }
        }
        .stroke(color.opacity(0.7), style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
        
        ForEach(Array(hand.joints.values)) { joint in
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
                .shadow(color: color, radius: 3)
                .position(x: joint.location.x * width, y: joint.location.y * height)
        }
    }
}
