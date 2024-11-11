//
//  SpeedOverlay.swift
//  WIPER
//
//  Created by Andrea Lima Blanca on 10/11/24.
//
import SwiftUI

struct SpeedOverlayView: View {
    @Binding var speed: Double // Vinculación para actualizar la velocidad en tiempo real

    var body: some View {
        VStack {
            Text(String(format: "%.0f", speed)) // Solo muestra la velocidad
                .font(.system(size: 30, weight: .bold)) // Tamaño grande y negrita
                .foregroundColor(.white)
            Text("km/h")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(width: 80, height: 80) // Tamaño cuadrado pequeño
        .background(Color.black.opacity(0.8))
        .cornerRadius(10)
        .shadow(radius: 5) // Sombra para darle profundidad
        .padding(20) // Separación del borde de la pantalla
    }
}
