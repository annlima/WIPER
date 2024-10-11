//
//  MainView.swift
//  WIPER
//
//  Created by Andrea Lima Blanca on 03/10/24.
//

import SwiftUI

struct MainView: View {
    var body: some View {
        TabView {
            
            FavoriteRoute()
                .tabItem {
                    Image(systemName: "map")
                    Text("Map")
                }
            
            CameraView()
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
