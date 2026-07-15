//
//  GuitarShape.swift
//  VisionHandPose
//
//  Created by Dylan Amadeus on 14/07/26.
//

import Foundation
import SwiftUI

struct GuitarString: Shape {
    var progress: CGFloat
    var y: CGFloat
    var vibration: CGFloat

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(progress, vibration) }
        set {
            progress = newValue.first
            vibration = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let yy = rect.height * y + vibration

        path.move(to: CGPoint(x: 0, y: yy))
        path.addLine(to: CGPoint(x: rect.width * progress, y: yy))

        return path
    }
}
