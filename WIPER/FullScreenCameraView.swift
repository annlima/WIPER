import SwiftUI

struct FullScreenCameraView: View {
    @Environment(\.presentationMode) var presentationMode // Para cerrar la vista de cámara
    @StateObject var cameraViewModel = CameraViewModel() // ViewModel para manejar la cámara
    @ObservedObject var cameraManager = CameraManager() // Manager de la cámara

    var body: some View {
        ZStack {
            CameraView()
                .ignoresSafeArea() // La cámara cubre toda la pantalla
                .onAppear {
                    // Bloquear la orientación a landscape cuando la cámara esté activa
                    lockOrientation(.landscape)
                }
                .onDisappear {
                    // Desbloquear la orientación cuando la cámara se cierre
                    lockOrientation(.all) // Permitir todas las orientaciones después de cerrar la cámara
                }
            
            VStack {
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss() // Cerrar la vista de la cámara
                    }) {
                        Text("Close")
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    Spacer()
                }
                .padding()

                Spacer()

                HStack {
                    Spacer()
                    // Botón de grabación
                    Button(action: {
                        if cameraViewModel.isRecording {
                            cameraViewModel.stopRecording()
                        } else {
                            cameraViewModel.startRecording(session: cameraManager.session)
                        }
                    }) {
                        Image(systemName: cameraViewModel.isRecording ? "stop.circle" : "record.circle")
                            .resizable()
                            .frame(width: 70, height: 70)
                            .foregroundColor(cameraViewModel.isRecording ? .red : .white)
                            .padding()
                    }
                }
            }
            .padding(.bottom, 30)
        }
    }

    // Función para bloquear la orientación
    func lockOrientation(_ orientation: UIInterfaceOrientationMask) {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.orientationLock = orientation
        }
    }
}
