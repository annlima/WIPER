import SwiftUI
import AVFoundation

struct CameraView: View {
    @StateObject var cameraViewModel = CameraViewModel()
    @StateObject var cameraManager = CameraManager()
    
    var body: some View {
        ZStack {
            FullScreenCameraView(cameraViewModel: cameraViewModel, cameraManager: cameraManager)
                .edgesIgnoringSafeArea(.all)
        }
    }
}

