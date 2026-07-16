//
//  LandingView.swift
//  VisionHandPose
//
//  Created by Dylan Amadeus on 14/07/26.
//

import SwiftUI

struct LandingView: View {
    let strings: [CGFloat] = [
        0.3,
        0.4,
        0.5,
        0.6,
        0.7,
        0.8
    ]

    @State private var path = NavigationPath()
    @State private var animate = false
    @State private var vibrate = false

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Color("PrimaryBackground").ignoresSafeArea()
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
                        Color.white,
                        lineWidth: 0.2
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

                RadialGradient(
                    colors: [
                        Color(
                            red: 200/255,
                            green: 148/255,
                            blue: 58/255
                        ).opacity(0.18),
                        .clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: 500
                )

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
                            .foregroundStyle(Color("PrimaryFont"))
                        Text("Where your hand become guitar")
                            .font(.custom("Playfair Display", size: 25))
                            .fontWeight(.regular)
                            .foregroundStyle(Color("SecondaryFont"))
                    }
                    .padding(.bottom, 50)


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
                            Spacer()
                            Text("\(Image(systemName: "chevron.right"))")
                                .foregroundStyle(Color("PrimaryFont"))
                                .font(Font.custom("Inter", size: 30))
                        }
                        .padding(.vertical, 30)
                        .padding(.horizontal, 100)
                        .background(Color("SecondaryFont"))
                        .cornerRadius(15)
                        .frame(maxWidth: 500)
                    }
                }
            }
            .onAppear {
                animate = true

                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    vibrate = true
                }
            }
            .navigationDestination(for: String.self) { value in
                if value == "MainGuitar" {
                    MainGuitarView(path: $path, manager: HandPoseManager(), chordPlayer: ChordPlayer())
                } else if value == "Guide" {
                    GuideView(path: $path)
                }
            }
        }
    }
}

#Preview {
    LandingView()
}
