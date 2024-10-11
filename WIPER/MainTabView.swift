import SwiftUI

struct MainView: View {
    var body: some View {
        TabView {
            CameraView()
                .tabItem {
                    Image(systemName: "camera")
                    Text("Camera")
                }
            
            FavoriteRoute()
                .tabItem {
                    Image(systemName: "map")
                    Text("Map")
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
