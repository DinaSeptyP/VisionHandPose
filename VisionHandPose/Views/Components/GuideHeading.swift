//
//  GuideHeading.swift
//  VisionHandPose
//
//  Created by Muhamad Yuan Sastro Dimianta on 16/07/26.
//

import SwiftUI

struct GuideHeading: View {
    @State var number: Int
    @State var logo: String
    @State var title: String
    @State var subtitle: String
    
    let titleSize: CGFloat
    let numberSize: CGFloat
    let iconSize: CGFloat
    let subtitleSize: CGFloat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ZStack(alignment: .leading) {
                Text("0\(number)")
                    .font(.custom("Playfair Display",size: numberSize))
                    .fontWeight(.black)
                    .foregroundStyle(Color("PrimaryBrown").opacity(0.15))
                
                Image(systemName: logo)
                    .font(.system(size: iconSize))
                    .foregroundStyle(.white)
                    .padding(20)
                    .background(Color("SecondaryFont"))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .offset(x: -0, y: 60)
            }
            
            Text(title)
                .font(.custom("Playfair Display",size: titleSize))
                .fontWeight(.black)
                .foregroundStyle(Color("PrimaryBackground"))
            
            Text(subtitle)
                .font(.custom("Inter", size: subtitleSize))
                .foregroundStyle(Color("PrimaryBackground"))
        }
    }
}

#Preview {
    GuideHeading(
        number: 1,
        logo: "guitars",
        title: "Apa kek",
        subtitle: "Test",
        titleSize: 44,
        numberSize: 90,
        iconSize: 24,
        subtitleSize: 24
    )
}
