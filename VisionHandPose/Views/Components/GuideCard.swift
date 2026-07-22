//
//  GuideCard.swift
//  VisionHandPose
//
//  Created by Dylan Amadeus on 15/07/26.
//

import SwiftUI

struct GuideCard<Content: View>: View {
    let number: Int
    let logo: String
    let title: String
    let tip: String
    let content: Content

    init(
        number: Int,
        logo: String,
        title: String,
        tip: String,
        @ViewBuilder content: () -> Content
    ) {
        self.number = number
        self.logo = logo
        self.title = title
        self.tip = tip
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header Section
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
            
            // Tip Section
            HStack(spacing: 12) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color("SecondaryFont"))
                
                Text(tip)
                    .font(.custom("Inter-Regular_SemiBold", size: 14, relativeTo: .subheadline))
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
            
            // Interactive Content Layer (Camera / Experience Visualizer)
            if Content.self != EmptyView.self {
                content
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
            }
        }
        .onAppear {
                        // Perulangan untuk mencetak semua font ke konsol Xcode
                        for family in UIFont.familyNames.sorted() {
                            print("Family: \(family)")
                            for font in UIFont.fontNames(forFamilyName: family) {
                                print("  - \(font)") // Gunakan nama ini di .font(.custom("Nama", size: 16))
                            }
                        }
                    }
        .padding(24)
    }
}

// Convenience initializer for static guide cards without custom embedded views
extension GuideCard where Content == EmptyView {
    init(
        number: Int,
        logo: String,
        title: String,
        tip: String
    ) {
        self.init(
            number: number,
            logo: logo,
            title: title,
            tip: tip,
            content: { EmptyView() }
        )
    }
}

#Preview {
    ZStack {
        Color("PrimaryFont").ignoresSafeArea()
        GuideCard(
            number: 1,
            logo: "guitars.fill",
            title: "Position Your Hand",
            tip: "Pastikan jarak tangan Anda berkisar antara 30-50 cm dari kamera."
        )
    }
}
