//
//  FavoriteRoute.swift
//  AppWIPER
//
//  Created by Andrea Lima Blanca on 28/05/23.
//

import SwiftUI
import MapKit
import CoreLocation

struct FavoriteRoute: View {
    @State private var mapRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 19.03793, longitude: -98.20346), span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2))
    
    struct Location: Identifiable {
        let id = UUID()
        let name: String
        let coordinate: CLLocationCoordinate2D
    }
    
    let locations = [
        Location(name: "Catedral", coordinate: CLLocationCoordinate2D(latitude: 19.04281015, longitude: -98.1983963)),
        Location(name: "Zócalo", coordinate: CLLocationCoordinate2D(latitude: 19.0438393, longitude: -98.1982317)),
        Location(name: "Pirámide de Cholula", coordinate: CLLocationCoordinate2D(latitude: 19.0579573, longitude: -98.3022263468972))
    ]
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                // Mapa de fondo
                Map(coordinateRegion: $mapRegion, annotationItems: locations) { location in
                    MapPin(coordinate: location.coordinate)
                }
                .edgesIgnoringSafeArea(.all)
                
                // Barra color crema con el título alineado a la izquierda
                VStack {
                    GeometryReader { geometry in
                        VStack {
                            Text("Lugares favoritos")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity, alignment: .leading) // Justificado a la izquierda
                                .padding(.leading, 16) // Espacio a la izquierda para separar del borde
                                .padding(.vertical, 12)
                                .background(Color("Color")) // Color crema sólido
                        }
                        .frame(width: geometry.size.width)
                    }
                    .frame(height: 60) // Altura de la capa debajo del título
                    
                    Spacer()
                }
                .padding(.top, 0)
            }
            .navigationBarHidden(true) // Ocultamos la barra de navegación para usar nuestro título personalizado
        }
    }
}

struct FavoriteRoute_Previews: PreviewProvider {
    static var previews: some View {
        FavoriteRoute()
    }
}
