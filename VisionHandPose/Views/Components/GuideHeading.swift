//
//  GuideHeading.swift
//  VisionHandPose
//
//  Created by Muhamad Yuan Sastro Dimianta on 16/07/26.
//

import SwiftUI

struct GuideHeading: View {
    let number: Int
    let logo: String
    let title: String
    
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("STEP 0\(number)")
                    .font(.custom("Inter-Bold", size: 12, relativeTo: .caption))
                    .foregroundStyle(Color("SecondaryFont"))
                    .tracking(2)
                
                Text(title)
                    .font(.custom("Inter-Bold", size: 30, relativeTo: .title))
                    .foregroundStyle(Color("PrimaryBackground"))
            }
            
            Spacer()
            
            Image(systemName: logo)
                .font(.system(size: 22))
                .foregroundStyle(.white)
                .padding(14)
                .background(Color("SecondaryFont"))
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .padding(.bottom, 16)
    }
}

#Preview {
    ZStack {
        Color("PrimaryFont").ignoresSafeArea()
        GuideHeading(number: 3, logo: "music.note.list", title: "Chord Guides")
            .padding()
    }
}
