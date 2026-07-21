//
//  LandingView.swift
//  VisionHandPose
//
//  Created by Dylan Amadeus on 14/07/26.
//

import SwiftUI

struct LandingView: View {
    let strings: [CGFloat] = [
        0.25,
        0.35,
        0.45,
        0.55,
        0.65,
        0.75
    ]
    
    @State private var path = NavigationPath()
    @State private var animate = false
    @State private var vibrate = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Color("PrimaryBackground").ignoresSafeArea()
                
                ZStack {
                    
                    Image(colorScheme == .dark
                          ? "GuitarBgDark"
                          : "GuitarBgLight")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    
                    RadialGradient(
                        colors: [
                            Color(
                                red: 200/255,
                                green: 148/255,
                                blue: 58/255
                            )
                            .opacity(0.08),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 500
                    )
                }
                NoiseView()
                ForEach(strings.indices, id: \.self) { index in
                    GuitarString(
                        progress: animate ? 1 : 0,
                        y: strings[index],
                        vibration: vibrate
                        ? CGFloat(index.isMultiple(of: 2) ? 2 : -2)
                        : 0
                    )
                    .stroke(
                        Color("PrimaryDark"), lineWidth: 0.2
                    )
                    .animation(
                        .easeOut(duration: 1.8)
                        .delay(0.2 + Double(index) * 0.15),
                        value: animate
                    )
                    .animation(
                        .easeInOut(duration: 0.08)
                        .repeatForever(autoreverses: true),
                        value: vibrate
                    )
                }
                
                VStack {
                    ZStack {
                        Image("Logo")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 400, height: 200)
                    }
                    VStack {
                        Text("StrumMe")
                            .font(.custom("Playfair Display", size: 100))
                            .fontWeight(.black)
                            .foregroundStyle(Color("PrimaryBrown"))
                        Text("Where your hand become guitar")
                            .font(.custom("Playfair Display", size: 28, relativeTo: .title))
                            .fontWeight(.regular)
                            .foregroundStyle(Color("SecondaryFont"))
                    }
                    .padding(.bottom, 50)
                    
                    HStack{
                        NavigationLink(value: "MainGuitar") {
                            HStack {
                                Text("\(Image(systemName: "hand.tap"))")
                                    .foregroundStyle(Color("PrimaryFont"))
                                    .font(Font.custom("Inter", size: 30))
                                    .padding(.trailing, 30)
                                Text("Begin Playing")
                                    .font(.custom("Inter", size: 30))
                                    .fontWeight(.medium)
                                    .foregroundStyle(Color("PrimaryFont"))
                            }
                            .padding(.vertical, 30)
                            .padding(.horizontal, 100)
                            .background(Color("SecondaryFont"))
                            .clipShape(Capsule())
                            .frame(maxWidth: 500)
                        }
                        NavigationLink(value: "Guide") {
                            HStack {
                                Text("\(Image(systemName: "info.circle"))")
                                    .foregroundStyle(Color("SecondaryFont"))
                                    .font(Font.custom("Inter", size: 30))
                                    .padding(.trailing, 30)
                                Text("View Guide")
                                    .font(.custom("Inter", size: 30))
                                    .fontWeight(.medium)
                                    .foregroundStyle(Color("SecondaryFont"))
                            }
                            .padding(.vertical, 30)
                            .padding(.horizontal, 100)
                            .background(Color("PrimaryFont"))
                            .clipShape(Capsule())
                            .frame(maxWidth: 500)
                        }
                    }
                }
            }
            
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now()) {
                    animate = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                    vibrate = true
                }
            }
            .navigationDestination(for: String.self) { value in
                if value == "MainGuitar" {
                    MainGuitarView(path: $path, manager: HandPoseManager(), chordPlayer: ChordPlayer())
                } else if value == "Guide" {
                    GuideView(path: $path, chordPlayer: ChordPlayer())
                }
            }
        }
    }
}

#Preview {
    LandingView()
}
