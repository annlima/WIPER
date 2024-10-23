import SwiftUI

struct MainView: View {
    @State private var showCameraFullScreen = false
    @State private var selectedTab: Int = 0
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemGray6
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
    
            FavoriteRoute()
                .tabItem {
                    Image(systemName: "map")
                    Text("Map")
                }
                .tag(0)
                .onAppear {
                    setTabBarColor(color: UIColor.systemGray6) // Fondo sólido para el mapa
                }
            
            // Pestaña de la cámara que abre la vista a pantalla completa directamente
            Color.clear // Esto es necesario para que el TabView funcione correctamente
                .tabItem {
                    Image(systemName: "camera")
                    Text("Camera")
                }
                .tag(1)
                .onAppear {
                    showCameraFullScreen = true // Abre la cámara directamente
                    setTabBarColor(color: UIColor.clear) // Hacer transparente la barra al ir a la cámara
                }
                .fullScreenCover(isPresented: $showCameraFullScreen) {
                    FullScreenCameraView()
                }
        }
        .accentColor(Color("Color")) // Personaliza el color seleccionado de la pestaña
    }

    // Función para cambiar el color de la barra de pestañas
    func setTabBarColor(color: UIColor) {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground() // Fondo sólido
        appearance.backgroundColor = color

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
