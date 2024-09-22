//
//  StartDrivingScreen.swift
//  AppWIPER
//
//  Created by Andrea Lima Blanca on 10/09/23.
//

import SwiftUI

struct StartDrivingScreen: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Bienvenido a WIPER")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color("Color"))
                    .padding(.top, 40)
                Text("La aplicación que cuida de tu seguridad al conducir.")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                HeaderStartDriving()
                
                HStack(spacing: 30) {
                    VStack {
                        Image(systemName: "shield.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                            .foregroundColor(Color("Color"))
                        Text("Seguridad")
                            .font(.footnote)
                            .foregroundColor(.gray)
                    }
                    VStack {
                        Image(systemName: "location.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                            .foregroundColor(Color("Color"))
                        Text("Ubicación")
                            .font(.footnote)
                            .foregroundColor(.gray)
                    }
                    VStack {
                        Image(systemName: "bell.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                            .foregroundColor(Color("Color"))
                        Text("Alertas")
                            .font(.footnote)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.vertical, 20)
                
                NavigationLink(destination: FavoriteRoute()) {
                                   ZStack {
                                       // Fondo del botón con gradiente y sombra
                                       LinearGradient(gradient: Gradient(colors: [Color("Color"), Color("Color")]), startPoint: .leading, endPoint: .trailing)
                                           .cornerRadius(20)
                                           .shadow(color: .gray.opacity(0.5), radius: 10, x: 0, y: 5)
                                       
                                       Text("¡Empezar a conducir!")
                                           .foregroundColor(.white)
                                           .font(.title2)
                                           .fontWeight(.bold)
                                           .padding()
                                   }
                                   .frame(height: 60) 
                }
                .padding(.top, 30)
                Spacer()
            }
            .padding()
            .background(Color("BackgroundColor").edgesIgnoringSafeArea(.all))
        }
    }
}

// Subvista para la cabecera que muestra el ícono de la app
struct HeaderStartDriving: View {
    var body: some View {
        VStack {
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
                .shadow(color: .gray.opacity(0.4), radius: 10, x: 0, y: 5)
                .padding(.bottom, 60)
        }
    }
}

struct StartDrivingScreen_Previews: PreviewProvider {
    static var previews: some View {
        StartDrivingScreen()
    }
}
