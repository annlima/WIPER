//
//  ContentView.swift
//  CameraWiper
//
//  Created by Andrea Lima Blanca on 04/06/23.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var cameraModel: CameraViewModel
    private let deviceModel: String = DeviceManager.shared.deviceModel

    var body: some View {
        SplashScreen()
            .onAppear {
                print("Modelo del dispositivo: \(deviceModel)")
            }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
