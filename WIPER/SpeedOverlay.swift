//
//  SpeedOverlay.swift
//  WIPER
//
//  Created by Andrea Lima Blanca on 10/11/24.
//

import SwiftUI

/// Una vista de SwiftUI que muestra la velocidad actual del vehículo como una superposición.
/// Está diseñada para ser visualmente clara y concisa, adecuada para una interfaz de conducción.
struct SpeedOverlayView: View {
    /// Una vinculación (binding) a una variable de tipo `Double` que representa la velocidad actual.
    /// `@Binding` permite que esta vista modifique y reaccione a los cambios en la variable `speed`
    /// que es propiedad de una vista o gestor de datos padre ( `LocationManager`).
    @Binding var speed: Double

    var body: some View {
        VStack {
            // Muestra el valor numérico de la velocidad.
            Text(String(format: "%.0f", speed))
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(.white)
            
            // Muestra la unidad de velocidad "km/h".
            Text("km/h")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        // Modificadores aplicados al VStack para darle estilo y dimensiones:
        .frame(width: 80, height: 80)
        .background(Color.black.opacity(0.8))
        .cornerRadius(10)
        .shadow(radius: 5)
        .padding(20)
    }
}
