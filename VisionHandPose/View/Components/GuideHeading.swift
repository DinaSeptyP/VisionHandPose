//
//  GuideHeading.swift
//  VisionHandPose
//
//  Created by Dylan Amadeus on 16/07/26.
//

import SwiftUI

struct GuideHeading: View {
    @State var number: Int
    @State var logo: String
    @State var title: String
    
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
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 10)
            }
            .frame(maxWidth: 600, alignment: .leading)
        }
    }
}

#Preview {
    GuideHeading(number: 1, logo: "guitars", title: "Apa kek")
}
