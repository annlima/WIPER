//
//  ContentView.swift
//  CameraWiper
//
//  Created by Andrea Lima Blanca on 04/06/23.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var cameraModel: CameraViewModel
    var body: some View {
        SplashScreen()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
