//
//  GuideView.swift
//  VisionHandPose
//
//  Created by Dylan Amadeus on 14/07/26.
//

import SwiftUI

struct GuideView: View {
    @Binding var path: NavigationPath
    var body: some View {
        HStack {
            ZStack {
                Color("PrimaryBackground")
                    .ignoresSafeArea()
                
                VStack(alignment: .leading) {
                    Text("G E T T I N G   S T A R T E D")
                        .font(.custom("Inter", size: 13))
                        .fontWeight(.medium)
                        .foregroundStyle(Color("SecondaryFont"))
                    
                    Text("How to")
                        .font(.custom("Playfair Display", size: 50))
                        .fontWeight(.black)
                        .foregroundStyle(Color("PrimaryFont"))
                    Text("Play")
                        .font(.custom("Playfair Display", size: 50))
                        .italic()
                        .fontWeight(.black)
                        .foregroundStyle(Color("PrimaryFont"))
                }
            }
            ZStack {
                Color("PrimaryFont")
            }
        }
    }
}

#Preview {
    GuideView(path: .constant(NavigationPath()))
}
