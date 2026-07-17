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
        VStack(alignment: .leading) {
            Text("Chord Detected")
                .font(.custom("Inter", size: 13))
                .fontWeight(.bold)
                .tracking(1.4)
                .foregroundStyle(Color("PrimaryBrown"))
            
            HStack(alignment: .firstTextBaseline, spacing: 7) {
                Text(manager.activeChord.rawValue + manager.activeNotesType.suffix)
                    .font(.custom("Playfair Display", size: 48))
                    .fontWeight(.black)
                
                Text(manager.activeStrumType == .none ? "—" : manager.activeStrumType.rawValue)
                    .font(.custom("Playfair Display", size: 28))
                    .fontWeight(.bold)
            }
            .padding(.bottom, -1)
            .foregroundStyle(Color("PrimaryBrown"))
            
            Text("\(manager.activeNotesType.suffix == "" ? "♮ Natural" : manager.activeNotesType.suffix == "#" ? "# Sharp" : "♭ Flat")")
                .font(.custom("Inter", size: 11))
                .fontWeight(.semibold)
                .foregroundStyle(Color("PrimaryBrown"))
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(Color("PrimaryBrown").opacity(0.16))
                .clipShape(Capsule())
        }
        .padding(.horizontal, 18)
        .padding(.vertical)
        .frame(width: 300, height: 150, alignment: .leading)
        .background(Color("PrimaryFont").opacity(0.88))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color("PrimaryBrown").opacity(0.65), lineWidth: 1)
        }
    }
}

#Preview {
    ChordResultCard(manager: HandPoseManager())
}
