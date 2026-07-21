//
//  ChordResultCard.swift
//  VisionHandPose
//
//  Created by Dylan Amadeus on 17/07/26.
//

import SwiftUI

struct ChordResultCard: View {
    @ObservedObject var manager: HandPoseManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("CHORD DETECTED")
                .font(.custom("Inter-Bold", size: 10, relativeTo: .caption))
                .tracking(1.4)
                .foregroundStyle(Color("PrimaryBrown").opacity(0.8))
            
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(manager.activeChord.rawValue)
                    .font(.custom("Inter-Bold", size: 32, relativeTo: .title))
                
                Text(manager.activeStrumType == .none ? "—" : manager.activeStrumType.rawValue)
                    .font(.custom("Inter-SemiBold", size: 18, relativeTo: .headline))
            }
            .foregroundStyle(Color("PrimaryBrown"))
            .padding(.bottom, 2)
            
            Text("\(manager.activeNotesType.suffix == "" ? "♮ Natural" : manager.activeNotesType.suffix == "#" ? "# Sharp" : "♭ Flat")")
                .font(.custom("Inter-SemiBold", size: 10, relativeTo: .caption2))
                .foregroundStyle(Color("PrimaryBrown"))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color("PrimaryBrown").opacity(0.12))
                .clipShape(Capsule())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(width: 220, height: 110, alignment: .leading)
        .background(Color("PrimaryFont").opacity(0.88))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color("PrimaryBrown").opacity(0.3), lineWidth: 1)
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        ChordResultCard(manager: HandPoseManager())
    }
}
