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
        }
    }
}
