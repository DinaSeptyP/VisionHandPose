//
//  ChordCard.swift
//  VisionHandPose
//
//  Created by Muhamad Yuan Sastro Dimianta on 16/07/26.
//

import SwiftUI

struct ChordCard: View {
    let chord: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image("Hand-\(chord)")
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .frame(maxHeight: 150)
            
            Text(chord)
                .font(.custom("Inter-Bold", size: 20, relativeTo: .headline))
                .foregroundStyle(Color("PrimaryBackground"))
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color("PrimaryBrown").opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color("PrimaryBackground").opacity(0.15), lineWidth: 1.5)
        )
        .shadow(color: .black.opacity(0.04), radius: 6, y: 3)
    }
}

#Preview {
    ZStack {
        Color("PrimaryFont").ignoresSafeArea()
        ChordCard(chord: "C")
            .padding()
    }
}
