//
//  drawHandSkeleton.swift
//  VisionHandPose
//
//  Created by Dylan Amadeus on 14/07/26.
//

import Foundation
import SwiftUI

private func cameraAspectFillPoint(
    _ normalizedPoint: CGPoint,
    width: CGFloat,
    height: CGFloat
) -> CGPoint {
    // AVCaptureVideoPreviewLayer uses resizeAspectFill. Vision points refer
    // to the complete 16:9 camera frame, so apply the same scale and crop to
    // the overlay instead of stretching normalized points to the iPad bounds.
    let cameraAspectRatio: CGFloat = 16.0 / 9.0
    let viewAspectRatio = width / max(height, 1)

    if viewAspectRatio < cameraAspectRatio {
        let renderedWidth = height * cameraAspectRatio
        let horizontalCrop = (renderedWidth - width) / 2
        return CGPoint(
            x: normalizedPoint.x * renderedWidth - horizontalCrop,
            y: normalizedPoint.y * height
        )
    }

    let renderedHeight = width / cameraAspectRatio
    let verticalCrop = (renderedHeight - height) / 2
    return CGPoint(
        x: normalizedPoint.x * width,
        y: normalizedPoint.y * renderedHeight - verticalCrop
    )
}

func drawHandSkeleton(_ hand: HandPose, width: CGFloat, height: CGFloat, color: Color) -> some View {
    Group {
        Path { path in
            for line in hand.skeletonLines {
                guard let first = line.first else { continue }
                path.move(to: cameraAspectFillPoint(first, width: width, height: height))
                for pt in line.dropFirst() {
                    path.addLine(to: cameraAspectFillPoint(pt, width: width, height: height))
                }
            }
        }
        .stroke(color.opacity(0.7), style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))

        ForEach(Array(hand.joints.values)) { joint in
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
                .shadow(color: color, radius: 3)
                .position(cameraAspectFillPoint(joint.location, width: width, height: height))
        }
    }
}
