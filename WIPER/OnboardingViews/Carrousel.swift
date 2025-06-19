import SwiftUI
import UserNotifications
import CoreLocation
import AVFoundation

// MARK: - Consistent Font Styles
struct OnboardingTextStyles {
    static let iconSize: CGFloat = 150
    static let titleFont: Font = .system(size: 42, weight: .bold)
    static let descriptionFont: Font = .title3
    static let buttonFont: Font = .system(size: 20, weight: .bold)
    static let buttonHeight: CGFloat = 50
    static let buttonWidth: CGFloat = 320
}

// MARK: - Onboarding View
struct Onboarding: View {
    @State private var selectedIndex = 0
    @StateObject private var locationManager = LocationManager()
    @State private var onboardingCompleted = false
    private let totalTabs = 5

    var body: some View {
        if onboardingCompleted {
            FavoriteRoute().environmentObject(locationManager)
        } else {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color("Color").opacity(0.7), Color("Color").opacity(0.9), Color("Color")]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    .edgesIgnoringSafeArea(.all)

                // TabView now uses the selectedIndex binding
                TabView(selection: $selectedIndex) {
                    // Pass the binding to selectedIndex to each tab
                    CameraPermissionTab(selectedIndex: $selectedIndex).tag(0)
                    NotificationsTab(selectedIndex: $selectedIndex).tag(1)
                    LocationPermissionTab(selectedIndex: $selectedIndex).tag(2)
                    PhonePositionTab(selectedIndex: $selectedIndex).tag(3)
                    GoTab(onboardingCompleted: $onboardingCompleted).tag(4)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .padding(.bottom, 80) // Keep space for bottom elements

                // Bottom elements (Page Indicator)
                VStack {
                    Spacer()
                    HStack(spacing: 8) {
                        ForEach(0..<totalTabs, id: \.self) { index in
                            Rectangle()
                                .frame(width: selectedIndex == index ? 25 : 8, height: 8)
                                .foregroundColor(selectedIndex == index ? Color.white : Color.gray.opacity(0.7))
                                .cornerRadius(4)
                                .animation(.spring(), value: selectedIndex)
                        }
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationBarBackButtonHidden(true)
            .environmentObject(locationManager)
             // Animate tab transitions
            .animation(.easeInOut, value: selectedIndex)
        }
    }
}

// MARK: - Preview
struct Onboarding_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            Onboarding()
                .preferredColorScheme(.light)
        }
    }
}

// MARK: - Camera Permission Tab
struct CameraPermissionTab: View {
    // Add binding to control the selected tab index
    @Binding var selectedIndex: Int

    @State private var cameraAuthorized = false
    @State private var showingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        VStack(spacing: 20) {
             Spacer(minLength: 20)

            Image(systemName: "camera.fill")
                .font(.system(size: OnboardingTextStyles.iconSize, weight: .bold))
                .foregroundColor(.white)
                .frame(maxHeight: OnboardingTextStyles.iconSize * 1.2, alignment: .center)

            Text("Permitir acceso a cámara")
                .font(OnboardingTextStyles.titleFont)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 20)

            Text("Para grabar tu recorrido y detectar objetos, necesitamos acceso a tu cámara.")
                .font(OnboardingTextStyles.descriptionFont)
                .foregroundColor(.white.opacity(0.9))
                .bold()
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()

            Button("Permitir acceso") {
                requestCameraPermission()
                selectedIndex += 1
            }
            .frame(width: OnboardingTextStyles.buttonWidth, height: OnboardingTextStyles.buttonHeight)
            .font(OnboardingTextStyles.buttonFont)
            .background(Color.white)
            .foregroundColor(Color("Color"))
            .cornerRadius(10)
            .alert(isPresented: $showingAlert) {
                Alert(title: Text("Permiso de cámara"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .padding(.bottom, 20)
        }
         .padding(.horizontal)
    }

    func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                cameraAuthorized = granted
                alertMessage = granted ? "¡Acceso a la cámara concedido!" : "Acceso denegado. Puedes habilitarlo en Ajustes."
                showingAlert = true
            }
        }
    }
}

// MARK: - Notifications Tab
struct NotificationsTab: View {
    @Binding var selectedIndex: Int

    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""

    var body: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 20)

            Image(systemName: "bell.badge.fill")
                .font(.system(size: OnboardingTextStyles.iconSize, weight: .bold))
                .foregroundColor(.white)
                .frame(maxHeight: OnboardingTextStyles.iconSize * 1.2, alignment: .center)

            Text("Activar notificaciones")
                .font(OnboardingTextStyles.titleFont)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 20)

            Text("Mantente alerta con avisos importantes sobre objetos detectados en tu camino.")
                .font(OnboardingTextStyles.descriptionFont)
                .foregroundColor(.white.opacity(0.9))
                .bold()
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()

            Button("Permitir notificaciones") {
                requestNotifications() // Request permission first
                // Advance to the next tab immediately on tap
                selectedIndex += 1
            }
            .frame(width: OnboardingTextStyles.buttonWidth, height: OnboardingTextStyles.buttonHeight)
            .font(OnboardingTextStyles.buttonFont)
            .background(Color.white)
            .foregroundColor(Color("Color"))
            .cornerRadius(10)
            .alert(isPresented: $showingAlert) {
                Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .padding(.bottom, 20)
        }
        .padding(.horizontal)
    }

    func requestNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                alertTitle = granted ? "Notificaciones activadas" : "Notificaciones desactivadas"
                alertMessage = granted ? "¡Gracias! Recibirás alertas importantes." : "Notificaciones desactivadas. Puedes cambiarlo en Ajustes."
                showingAlert = true
            }
        }
    }
}

// MARK: - Location Permission Tab
struct LocationPermissionTab: View {
    @Binding var selectedIndex: Int
    @EnvironmentObject var locationManager: LocationManager
    @State private var showingThanksAlert = false

    var body: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 20)

            Image(systemName: "location.fill")
                .font(.system(size: OnboardingTextStyles.iconSize, weight: .bold))
                .foregroundColor(.white)
                 .frame(maxHeight: OnboardingTextStyles.iconSize * 1.2, alignment: .center)

            Text("Permitir acceso a ubicación")
                .font(OnboardingTextStyles.titleFont)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 20)

            Text("Necesitamos tu ubicación para mostrar tu velocidad y calcular rutas.")
                .font(OnboardingTextStyles.descriptionFont)
                .foregroundColor(.white.opacity(0.9))
                .bold()
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()

            Button("Permitir ubicación") {
                locationManager.requestLocationAuthorization()
                selectedIndex += 1
                 DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { // Increased delay slightly
                     if locationManager.authorizationStatus == .authorizedWhenInUse || locationManager.authorizationStatus == .authorizedAlways {
                         showingThanksAlert = true
                     }
                 }
            }
            .frame(width: OnboardingTextStyles.buttonWidth, height: OnboardingTextStyles.buttonHeight)
            .font(OnboardingTextStyles.buttonFont)
            .background(Color.white)
            .foregroundColor(Color("Color"))
            .cornerRadius(10)
            .alert(isPresented: $showingThanksAlert) {
                Alert(title: Text("Permiso concedido"), message: Text("Gracias por permitir el acceso a la ubicación."), dismissButton: .default(Text("OK")))
            }
            .padding(.bottom, 20)
        }
        .padding(.horizontal)
         .onAppear {
              if locationManager.authorizationStatus == .notDetermined {
                   locationManager.requestLocationAuthorization()
              }
         }
    }
}

// MARK: - Phone Position Tab
struct PhonePositionTab: View {
    @Binding var selectedIndex: Int

    var body: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 20)

            Image(systemName: "iphone.gen1.landscape")
                .font(.system(size: OnboardingTextStyles.iconSize, weight: .bold))
                .foregroundColor(.white)
                .frame(maxHeight: OnboardingTextStyles.iconSize * 1.2, alignment: .center)

            Text("Posición del teléfono")
                .font(OnboardingTextStyles.titleFont)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 20)

            Text("Para una mejor detección, coloca tu teléfono horizontalmente, **debajo del espejo retrovisor**, con la cámara trasera apuntando hacia adelante.")
                .font(OnboardingTextStyles.descriptionFont)
                .foregroundColor(.white.opacity(0.9))
                .bold()
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()

            Button("Entendido") {
                selectedIndex += 1
            }
            .frame(width: OnboardingTextStyles.buttonWidth, height: OnboardingTextStyles.buttonHeight)
            .font(OnboardingTextStyles.buttonFont)
            .background(Color.white)
            .foregroundColor(Color("Color"))
            .cornerRadius(10)
            .padding(.bottom, 20)
        }
        .padding(.horizontal)
    }
}

// MARK: - Go Tab
struct GoTab: View {
    @Binding var onboardingCompleted: Bool

    var body: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 20)

            Image(systemName: "figure.wave")
                .font(.system(size: OnboardingTextStyles.iconSize, weight: .bold))
                .foregroundColor(.white)
                .frame(maxHeight: OnboardingTextStyles.iconSize * 1.2, alignment: .center)

            Text("¡Todo listo!")
                .font(OnboardingTextStyles.titleFont)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 20)

            Text("¡Ya puedes comenzar a usar WIPER! Presiona 'Comenzar' para ir al mapa.")
                .font(OnboardingTextStyles.descriptionFont)
                .foregroundColor(.white.opacity(0.9))
                .bold()
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()

            Button("Comenzar") {
                onboardingCompleted = true
            }
            .frame(width: OnboardingTextStyles.buttonWidth, height: OnboardingTextStyles.buttonHeight)
            .font(OnboardingTextStyles.buttonFont)
            .background(Color.white)
            .foregroundColor(Color("Color"))
            .cornerRadius(10)
            .padding(.bottom, 20)
        }
        .padding(.horizontal)
        .foregroundColor(.white)
    }
}
