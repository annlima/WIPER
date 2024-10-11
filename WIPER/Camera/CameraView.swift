//
//  CameraView.swift
//  WIPER
//
//  Created by Andrea Lima Blanca on 24/09/24.
//

import AVFoundation
import SwiftUI

struct CameraView: View {
    @StateObject var cameraViewModel = CameraViewModel()
    @StateObject var cameraManager = CameraManager()
    
    var body: some View {
        ZStack {
            CameraPreview(captureSession: cameraManager.session)
                .edgesIgnoringSafeArea(.all)
                .onAppear {
                    cameraManager.setUp(cameraViewModel: cameraViewModel) { result in
                        switch result {
                        case .success():
                            cameraManager.session.startRunning()
                        case .failure(let error):
                            print("Error: \(error)")
                        }
                    }
                }
            
            ForEach(cameraViewModel.detectedObjects) { object in
                Rectangle()
                    .stroke(Color.red, lineWidth: 2)
                    .frame(width: object.boundingBox.width * UIScreen.main.bounds.width,
                           height: object.boundingBox.height * UIScreen.main.bounds.height)
                    .offset(x: object.boundingBox.minX * UIScreen.main.bounds.width,
                            y: (1 - object.boundingBox.minY) * UIScreen.main.bounds.height)
                    .overlay(
                        Text("\(object.identifier) \(Int(object.confidence * 100))%")
                            .foregroundColor(.red)
                            .background(Color.white)
                            .font(.caption)
                            .padding(5)
                            .offset(x: 0, y: -10)
                    )
            }
        }
    }
}
