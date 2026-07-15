//
//  NoiseView.swift
//  VisionHandPose
//
//  Created by Dylan Amadeus on 14/07/26.
//

import SwiftUI

struct NoiseView: View {
    var body: some View {
        Canvas { context, size in
            for _ in 0..<4000 {
                let x = CGFloat.random(in: 0...size.width)
                let y = CGFloat.random(in: 0...size.height)

                context.fill(
                    Path(CGRect(x: x, y: y, width: 1, height: 1)),
                    with: .color(Color("SecondaryFont"))
                )
            }
        }
        .opacity(0.3)
        .ignoresSafeArea()
    }
}

#Preview {
    NoiseView()
}
