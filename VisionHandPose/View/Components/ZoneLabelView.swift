//
//  ZoneLabelView.swift
//  VisionHandPose
//
//  Created by Dylan Amadeus on 14/07/26.
//

import SwiftUI

struct ZoneLabelView: View {
    let title: String
    let color: Color
    let x: CGFloat
    let y: CGFloat
    
    var body: some View {
        Text(title)
            .font(.custom("Inter", size: 17))
            .foregroundColor(Color("PrimaryFont"))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.5))
            .clipShape(Capsule())
            .position(x: x, y: y)
    }
}

#Preview {
    ZoneLabelView(title: "Apa ya", color: .red, x: 100, y: 500)
}
