//
//  GuideTipCard.swift
//  VisionHandPose
//
//  Created by Dylan Amadeus on 16/07/26.
//

import SwiftUI

struct GuideTipCard: View {
    @State var tip: String
    var body: some View {
        HStack {
            Text("\(Image(systemName: "lightbulb.max"))")
                .font(.custom("Inter", size: 20))
                .foregroundStyle(Color("SecondaryFont"))
            Text(tip)
                .font(.custom("Inter", size: 20))
                .fontWeight(.light)
                .foregroundStyle(Color("PrimaryBrown"))
        }
        .padding()
        .background(Color("SecondaryFont").opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color("SecondaryFont"), lineWidth: 0.5)
        )
    }
}

#Preview {
    GuideTipCard(tip: "Apa kek")
}
