import SwiftUI

struct SplashScreen: View {
    @State private var isAnimating = false
    @State private var navigateToStartScreen = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("BackgroundColor") // Fondo de la splash screen
                    .edgesIgnoringSafeArea(.all)
                
                // Efecto de la cámara abriéndose con dos círculos
                Circle()
                    .fill(Color("Color"))
                    .scaleEffect(isAnimating ? 3 : 0.1) // El círculo se expande
                    .animation(.easeOut(duration: 1)) // Animación para abrir
                    .onAppear {
                        // Inicia la animación cuando aparece la vista
                        withAnimation {
                            isAnimating = true
                        }
                        // Desencadena la navegación después de 1 segundo
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                            navigateToStartScreen = true
                        }
                    }
                
                NavigationLink(destination: StartScreen(), isActive: $navigateToStartScreen) {
                    EmptyView()
                }
            }
        }
    }
}

struct SplashScreen_Previews: PreviewProvider {
    static var previews: some View {
        SplashScreen()
    }
}
