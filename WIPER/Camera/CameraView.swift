import SwiftUI
import AVFoundation

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
                            print("Sesión configurada y en ejecución")
                        case .failure(let error):
                            print("Error: \(error)")
                        }
                    }
                }
            
            VStack {
                Spacer()
                Button(action: {
                    if cameraViewModel.isRecording {
                        cameraManager.stopRecording(cameraViewModel: cameraViewModel)
                    } else {
                        cameraManager.startRecording(cameraViewModel: cameraViewModel)
                    }
                }) {
                    Image(systemName: cameraViewModel.isRecording ? "stop.circle" : "record.circle")
                        .resizable()
                        .frame(width: 70, height: 70)
                        .foregroundColor(cameraViewModel.isRecording ? .red : .white)
                        .padding()
                }
            }
            .padding(.bottom, 30)
        }
        .alert(isPresented: $cameraViewModel.showSaveDialog) {
            Alert(
                title: Text("Guardar video"),
                message: Text("¿Deseas guardar el video en la galería?"),
                primaryButton: .default(Text("Guardar")) {
                    if let url = cameraViewModel.previewUrl {
                        cameraViewModel.saveVideoToGallery(url: url)
                    }
                },
                secondaryButton: .cancel(Text("Cancelar"))
            )
        }
    }
}
