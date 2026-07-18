//
//  GuideTipCard.swift
//  VisionHandPose
//
//  Created by Muhamad Yuan Sastro Dimianta on 16/07/26.
//

import SwiftUI

struct GuideTipCard: View {
    let tip: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 16))
                .foregroundStyle(Color("SecondaryFont"))
            
            Text(tip)
                .font(.custom("Inter-Medium", size: 14, relativeTo: .subheadline))
                .foregroundStyle(Color("PrimaryBackground").opacity(0.9))
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("SecondaryFont").opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color("SecondaryFont").opacity(0.15), lineWidth: 1)
        }
    }
}

#Preview {
    ZStack {
        Color("PrimaryFont").ignoresSafeArea()
        GuideTipCard(tip: "Greater Camera View, Easy Chord Recognition")
            .padding()
    }
}
