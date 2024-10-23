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
                    setTabBarColor(color: UIColor.systemGray6)
                }
            Color.clear
                .tabItem {
                    Image(systemName: "camera")
                    Text("Camera")
                }
                .tag(1)
                .onAppear {
                    showCameraFullScreen = true
                    setTabBarColor(color: UIColor.clear)
                }
                .fullScreenCover(isPresented: $showCameraFullScreen) {
                    FullScreenCameraView()
                }
        }
        .accentColor(Color("Color"))
    }
    func setTabBarColor(color: UIColor) {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground() 
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
