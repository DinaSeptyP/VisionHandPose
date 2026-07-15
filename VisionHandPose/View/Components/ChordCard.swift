//
//  ChordCard.swift
//  VisionHandPose
//
//  Created by Dylan Amadeus on 15/07/26.
//

import SwiftUI

struct ChordCard: View {
    let chord: String
    var body: some View {
        VStack(spacing: 12) {
            Image("Hand-\(chord)")
                .resizable()
                .scaledToFit()
                .cornerRadius(12)
                .frame(maxHeight: 150)
            
            Text(chord)
                .font(.custom("Playfair Display", size: 25))
                .fontWeight(.bold)
                .foregroundStyle(Color("PrimaryBackground"))
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color("PrimaryBrown").opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color("PrimaryBackground").opacity(0.3), lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
    }
}

#Preview {
    ChordCard(chord: "C")
}
