import SwiftUI

struct FullScreenCameraView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var cameraViewModel: CameraViewModel   // Usar instancia pasada
    @ObservedObject var cameraManager: CameraManager       // Usar instancia pasada
    @State private var isNavigatingToMap = false
    @State private var speed: Double = 0.0 // Estado para la velocidad
    @ObservedObject var locationManager = LocationManager()
    
    var body: some View {
        ZStack {
            CameraPreview(captureSession: cameraManager.session)
                .ignoresSafeArea()
                .navigationBarHidden(true)
                .onAppear {
                    cameraManager.setUp(cameraViewModel: cameraViewModel) { result in
                        switch result {
                        case .success:
                            print("Sesión configurada y en ejecución en FullScreenCameraView")
                        case .failure(let error):
                            print("Error al configurar la cámara en FullScreenCameraView: \(error.localizedDescription)")
                        }
                    }
                    lockOrientation(.landscape)
                }
                .onDisappear {
                    cameraManager.session.stopRunning()
                    lockOrientation(.all)
                }
            
            SpeedOverlayView(speed: $locationManager.speed)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            
            // Dibujar bounding boxes
            ForEach(cameraViewModel.detections, id: \.self) { rect in
                Rectangle()
                    .path(in: rect)
                    .stroke(Color.red, lineWidth: 2)
                    .background(Rectangle().fill(Color.clear))
            }
            
            VStack {
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Cerrar")
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    Spacer()
                }
                .padding(.top, 30)
                .padding(.horizontal, 20)
                Spacer()

                HStack {
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
                    .disabled(!cameraManager.isSessionRunning)
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
                    isNavigatingToMap = true // Navegar al mapa
                },
                secondaryButton: .cancel(Text("Cancelar")) { // Botón de cancelar estilo predeterminado
                    isNavigatingToMap = true // Navegar al mapa
                }
            )
        }
        .onChange(of: isNavigatingToMap) { navigate in
            if navigate {
                navigateToMap()
                isNavigatingToMap = false
            }
        }
    }
    
    
    func navigateToMap() {
        presentationMode.wrappedValue.dismiss() // Regresa a la vista de mapa
    }

    func lockOrientation(_ orientation: UIInterfaceOrientationMask) {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.orientationLock = orientation
        }
    }
}
