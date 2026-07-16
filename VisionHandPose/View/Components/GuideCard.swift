//
//  GuideCard.swift
//  VisionHandPose
//
//  Created by Dylan Amadeus on 15/07/26.
//

import SwiftUI

struct GuideCard: View {
    @State var number: Int
    @State var logo: String
    @State var title: String
    @State var subtitle: String
    @State var tip: String
    var body: some View {
        VStack(alignment: .leading) {
            GuideHeading(number: number, logo: logo, title: title)
            Text(subtitle)
                .font(.custom("Inter", size: 23))
                .fontWeight(.regular)
                .foregroundStyle(Color("PrimaryBackground"))
                .frame(maxWidth: 600, alignment: .leading)
                .padding(.bottom, 50)
            
            GuideTipCard(tip: tip)
        }
        .padding()
        .padding(.top, -50)
    }
}

#Preview {
    GuideCard(
        number: 1,
        logo: "guitars",
        title: "Position Your Hand",
        subtitle: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.",
        tip: "Lorem ipsum dolor sit amet"
    )
}
