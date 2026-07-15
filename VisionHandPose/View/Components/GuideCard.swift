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
            VStack(alignment: .leading) {
                Text("0\(number)")
                    .font(.custom("Playfair Display", size: 180))
                    .fontWeight(.black)
                    .foregroundStyle(Color("PrimaryBrown").opacity(0.2))
                Text("\(Image(systemName: "\(logo)"))")
                    .font(.custom("Playfair Display", size: 40))
                    .foregroundStyle(Color("PrimaryFont"))
                    .padding(25)
                    .background(Color("SecondaryFont").opacity(0.9))
                    .cornerRadius(20)
                    .padding(.top, -220)
            }
            .padding(.bottom, -100)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.custom("Playfair Display", size: 60))
                    .fontWeight(.black)
                    .foregroundStyle(Color("PrimaryBackground"))
                    .lineLimit(2)
                    .padding(.bottom, 10)
                Text(subtitle)
                    .font(.custom("Inter", size: 23))
                    .fontWeight(.regular)
                    .foregroundStyle(Color("PrimaryBackground"))
            }
            .padding(.bottom, 50)
            
            HStack {
                Text("\(Image(systemName: "lightbulb.max"))")
                    .font(.custom("Inter", size: 20))
                    .foregroundStyle(Color("SecondaryFont"))
                Text("Tip: " + tip)
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
        .padding()
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
