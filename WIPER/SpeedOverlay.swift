//
//  SpeedOverlay.swift
//  WIPER
//
//  Created by Andrea Lima Blanca on 10/11/24.
//
import SwiftUI

struct SpeedOverlayView: View {
    @Binding var speed: Double

    var body: some View {
        VStack {
            Text(String(format: "%.0f", speed))
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(.white)
            Text("km/h")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(width: 80, height: 80)
        .background(Color.black.opacity(0.8))
        .cornerRadius(10)
        .shadow(radius: 5)
        .padding(20)
    }
}
