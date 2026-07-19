//
//  GuidePageHeader.swift
//  VisionHandPose
//
//  Created by Syahra Zulya Shania Maghfiroh on 19/07/26.
//

import SwiftUI

struct GuidePageHeader: View {
    let number: Int
    let logo: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ZStack(alignment: .leading) {
                Text("0\(number)")
                    .font(.custom("Playfair Display", size: 120))
                    .fontWeight(.black)
                    .foregroundStyle(
                        Color("PrimaryBrown").opacity(0.15)
                    )

                Image(systemName: logo)
                    .font(.system(size: 32))
                    .foregroundStyle(.white)
                    .padding(20)
                    .background(Color("SecondaryFont"))
                    .clipShape(
                        RoundedRectangle(cornerRadius: 18)
                    )
                    .offset(y: 60)
            }

            Text(title)
                .font(.custom("Playfair Display", size: 54))
                .fontWeight(.black)
                .foregroundStyle(Color("PrimaryBackground"))

            Text(subtitle)
                .id(subtitle)
                .font(.custom("Inter", size: 22))
                .foregroundStyle(Color("PrimaryBackground"))
                .transition(.opacity)
        }
        .animation(.easeInOut(duration: 0.25), value: subtitle)
    }
}

#Preview {
    GuidePageHeader(
        number: 4,
        logo: "hand.draw.fill",
        title: "Draw",
        subtitle: "Draw your hand to get the result"
    )
}
