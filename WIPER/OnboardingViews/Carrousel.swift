//
//  Carrousel.swift
//  WIPER
//
//  Created by Andrea Lima Blanca on 22/09/24.
//
import SwiftUI
import UserNotifications
import CoreLocation
import AVFoundation

struct Onboarding: View {
    @State private var selectedIndex = 0
    @State private var onboardingCompleted = false

    var body: some View {
        if onboardingCompleted{
            FavoriteRoute()
        }
        else
        {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color("Color").opacity(0.7), Color("Color").opacity(0.9), Color("Color")]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    .edgesIgnoringSafeArea(.all)
                
                TabView(selection: $selectedIndex) {
                    WelcomeTab(selectedIndex: $selectedIndex).tag(0)
                    CameraPermissionTab(selectedIndex: $selectedIndex).tag(1)
                    NotificationsTab(selectedIndex: $selectedIndex).tag(2)
                    LocationPermissionTab().tag(3)
                    GoTab(onboardingCompleted: $onboardingCompleted).tag(4)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                VStack {
                    Spacer()
                    HStack(spacing: 8) {
                        ForEach(0..<5) { index in
                            Rectangle()
                                .frame(width: selectedIndex == index ? 20 : 8, height: 8)
                                .foregroundColor(selectedIndex == index ? Color.white : Color.gray)
                                .cornerRadius(4)
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
            .navigationBarBackButtonHidden(true)
        }
    }
}

struct Onboarding_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView{
            Onboarding()
                .preferredColorScheme(.light)
        }
    }
}

// MARK: - WelcomeTab
struct WelcomeTab: View {
    @Binding var selectedIndex: Int
    @State private var userName: String = ""
    
    var body: some View {
        VStack {
            
            HStack {
                Image(systemName: "person.crop.square")
                    .font(.system(size: 190, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.leading, 20)
                Spacer()
            }
            .padding(.top, 40)
            
            Text("¿Cuál es tu nombre?")
                .font(.system(size: 60, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.top, 20)
                .multilineTextAlignment(.leading)
            
            TextField("Escribe tu nombre", text: $userName)
                .padding() // Espaciado interno
                .background(Color.white) // Fondo blanco
                .cornerRadius(10) // Esquinas redondeadas sin borde visible
                .padding(.horizontal, 40)
                .foregroundColor(Color("Color"))

            
            // Botón para confirmar el nombre
            Button("Continuar") {
                if !userName.isEmpty {
                    selectedIndex = 1
                }
            }
            .frame(width: 320, height: 50)
            .font(.system(size: 20, weight: .bold))
            .background(Color.white)
            .foregroundColor(Color("Color"))
            .cornerRadius(10)
            .padding(.top, 20)
            
            Spacer()
        }
    }
}


// MARK: - LocationPermissionTab
struct LocationPermissionTab: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var locationManager: LocationManager
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "location.fill")
                    .font(.system(size: 190, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.leading, 20)
                Spacer()
            }
            .padding(.top, 40)
            
            Text("Permitir acceso a ubicación")
                .font(.system(size: 60, weight: .bold))
                .foregroundColor(.white)
                .padding(.top, 20)
                .padding(.bottom, 1)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 40)
            Text("Necesitamos acceso a tu ubicación para darte indicaciones")
                .font(.system(size: 20))
                .foregroundColor(.white)
                .bold()
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 40)
            
            Spacer()
            
            Button("Permitir ubicación") {
                locationManager.requestLocationAuthorization()
            }
            .frame(width: 320, height: 50)
            .font(.system(size: 20, weight: .bold))
            .background(Color.white)
            .foregroundColor(Color("Color"))
            .cornerRadius(10)
            .padding(.bottom, 50)
        }
    }
}



// MARK: - GoTab
struct GoTab: View {
    @Binding var onboardingCompleted: Bool
    var body: some View {
        VStack {
            Spacer()
            Image(systemName: "car.2.fill")
                .font(.system(size: 180, weight: .bold))
                .rotationEffect(.degrees(-45))
            Text("¡Estás listo!")
                .font(.system(size: 50, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.top, 40)
                .padding(.bottom, 1)
            Button("Comenzar a manejar") {
                onboardingCompleted = true
                        }
                            .frame(width: 320, height: 75)
                            .font(.system(size: 25, weight: .bold))
                            .background(Color.white)
                            .foregroundColor(Color("Color"))
                            .cornerRadius(10)
                            .padding(.top, 50)
                        Spacer()
            
        }
        
        .foregroundColor(.white)
    }
}

// MARK: - Notifications
struct NotificationsTab: View {
    @Binding var selectedIndex: Int
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""

    var body: some View {
        VStack {
            // Imagen alineada a la izquierda
            HStack {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 190, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.leading, 20)
                Spacer()
            }
            .padding(.top, 40)
            
            Text("Activar notificaciones")
                .font(.system(size: 55, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.top, 20)
                .padding(.bottom, 1)
                .multilineTextAlignment(.leading)
            
            Text("Mantente alerta de los objetos a tu alrededor")
                .font(.system(size: 20))
                .foregroundColor(.white)
                .bold()
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 40)
            
            Spacer()
            
            Button("Permitir notificaciones") {
                requestNotifications()
            }
            .frame(width: 320, height: 50)
            .font(.system(size: 20, weight: .bold))
            .background(Color.white)
            .foregroundColor(Color("Color"))
            .cornerRadius(10)
            .padding(.bottom, 50)
            .alert(isPresented: $showingAlert) {
                Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    func requestNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    alertTitle = "Notificaciones activadas"
                    alertMessage = "¡Gracias por activar las notificaciones! Ahora recibirás las últimas actualizaciones directamente."
                } else {
                    alertTitle = "Notificaciones Desactivadas"
                    alertMessage = "Has desactivado las notificaciones. Puedes cambiar esto en cualquier momento desde los ajustes de tu dispositivo."
                }
                showingAlert = true
                selectedIndex = (selectedIndex + 1) % 6
            }
        }
    }
}


// MARK: - CameraPermissionTab
struct CameraPermissionTab: View {
    @Binding var selectedIndex: Int
    @State private var cameraAuthorized = false
    @State private var showingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        VStack {
            // Imagen alineada a la izquierda
            HStack {
                Image(systemName: "camera.fill")
                    .font(.system(size: 180, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.leading, 20)
                Spacer()
            }
            .padding(.top, 40)
            
            Text("Permitir acceso a la cámara")
                .font(.system(size: 60, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 28)
                .padding(.top, 20)
                .padding(.bottom, 1)
                .multilineTextAlignment(.leading)
            
            Text("Para grabar tu recorrido necesitamos acceso a tu cámara.")
                .font(.system(size: 20))
                .foregroundColor(.white)
                .bold()
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 40)
            
            Spacer()
            
            Button("Permitir") {
                requestCameraPermission()
            }
            .frame(width: 320, height: 50)
            .font(.system(size: 20, weight: .bold))
            .background(Color.white)
            .foregroundColor(Color("Color"))
            .cornerRadius(10)
            .padding(.bottom, 50)
            .alert(isPresented: $showingAlert) {
                Alert(title: Text("Permiso de cámara"), message: Text(alertMessage), dismissButton: .default(Text("OK"), action: {
                    if cameraAuthorized {
                        selectedIndex = (selectedIndex + 1) % 6
                    }
                }))
            }
        }
    }

    func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                if granted {
                    cameraAuthorized = true
                    alertMessage = "El acceso a la cámara ha sido concedido."
                } else {
                    alertMessage = "El acceso a la cámara ha sido denegado. Por favor, habilítalo en la configuración."
                }
                showingAlert = true
            }
        }
    }
}




