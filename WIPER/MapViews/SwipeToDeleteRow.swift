//
//  SwipeToDeleteRow.swift
//  WIPER
//
//  Created by Andrea Lima Blanca on 10/11/24.
//
import Foundation
import CoreLocation
import SwiftUI


struct SwipeToDeleteRow: View {
    let location: FavoriteRoute.Location
    let onDelete: () -> Void
    let onSelect: () -> Void

    @State private var offset: CGFloat = 0

    var body: some View {
        ZStack {
            // Botón de eliminar en el fondo
            HStack {
                Spacer()
                Button(action: {
                    withAnimation {
                        onDelete()
                    }
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                }
                .background(Color.red)
                .cornerRadius(8)
                .padding(.trailing, 16)
            }

            // Contenido principal con gesto de toque y deslizar
            Text(location.name)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .foregroundColor(.black)
                .background(Color.white)
                .offset(x: offset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if value.translation.width < 0 {
                                offset = value.translation.width
                            }
                        }
                        .onEnded { value in
                            if -offset > 80 {
                                // Mostrar botón de eliminar
                                offset = -100
                            } else {
                                // Volver a la posición original
                                offset = 0
                            }
                        }
                )
                .onTapGesture {
                    onSelect()
                }
                .animation(.easeInOut, value: offset)
        }
        .frame(height: 60)
    }
}


