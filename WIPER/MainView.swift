import SwiftUI

struct MainView: View {
    @State private var showCameraFullScreen = false // Estado para manejar la presentación a pantalla completa
    
    var body: some View {
        TabView {
            
            FavoriteRoute()
                .tabItem {
                    Image(systemName: "map")
                    Text("Map")
                }
            
            // Pestaña de la cámara que abre la vista a pantalla completa
            Button(action: {
                showCameraFullScreen.toggle()
            }) {
                VStack {
                    Image(systemName: "camera")
                    Text("Camera")
                }
            }
            .fullScreenCover(isPresented: $showCameraFullScreen) {
                FullScreenCameraView()
            }
            .tabItem {
                Image(systemName: "camera")
                Text("Camera")
            }
        }
        .accentColor(Color("Color")) // Customize the selected tab color
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
