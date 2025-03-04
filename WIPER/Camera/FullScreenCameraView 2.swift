//
//  FullScreenCameraView.swift
//  WIPER
//
//  Created by Andrea Lima Blanca on 24/09/24.
//

import SwiftUI
import AVFoundation

/**
 Vista principal de cámara a pantalla completa de WIPER.
 Integra la previsualización de la cámara, detección de objetos, velocidad actual
 y controles para grabar videos del trayecto.
 */
struct FullScreenCameraView: View {
    // MARK: - Propiedades
    
    /// Ambiente para control de navegación
    @Environment(\.presentationMode) var presentationMode
    
    /// ViewModel que gestiona la captura, procesamiento y detección
    @ObservedObject var cameraViewModel: CameraViewModel
    
    /// Gestor que controla la sesión de cámara y configuración
    @ObservedObject var cameraManager: CameraManager
    
    /// Estado de navegación
    @State private var isNavigatingToMap = false
    
    /// Velocidad actual (aunque se usa locationManager.speed directamente en la vista)
    @State private var speed: Double = 0.0
    
    /// Gestor de ubicación para obtener datos de velocidad
    @ObservedObject var locationManager = LocationManager()
    
    // MARK: - Vista

    var body: some View {
        ZStack {
            // Capa 1: Previsualización de la cámara
            CameraPreview(captureSession: cameraManager.session)
                .ignoresSafeArea()
                .navigationBarHidden(true)
                .onAppear {
                    // Configurar la sesión de cámara cuando aparece la vista
                    cameraManager.setUp(cameraViewModel: cameraViewModel) { result in
                        switch result {
                        case .success:
                            print("Sesión configurada y en ejecución en FullScreenCameraView")
                        case .failure(let error):
                            print("Error al configurar la cámara en FullScreenCameraView: \(error.localizedDescription)")
                        }
                    }
                    // Bloquear la orientación en modo paisaje
                    lockOrientation(.landscape)
                }
                .onDisappear {
                    // Limpiar cuando la vista desaparece
                    cameraManager.session.stopRunning()
                    lockOrientation(.all)
                }
            
            // Capa 2: Indicador de velocidad
            SpeedOverlayView(speed: $locationManager.speed)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            
            // Capa 3: Cajas delimitadoras para objetos detectados
            ForEach(cameraViewModel.detections, id: \.self) { rect in
                Rectangle()
                    .path(in: rect)
                    .stroke(Color.red, lineWidth: 2)
                    .background(Rectangle().fill(Color.clear))
            }
            
            // Capa 4: Controles de interfaz
            VStack {
                // Botón para cerrar la vista
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

                // Botón para iniciar/detener grabación
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
        // Diálogo para guardar el video
        .alert(isPresented: $cameraViewModel.showSaveDialog) {
            Alert(
                title: Text("Guardar video"),
                message: Text("¿Deseas guardar el video en la galería?"),
                primaryButton: .default(Text("Guardar")) {
                    if let url = cameraViewModel.previewUrl {
                        cameraViewModel.saveVideoToGallery(url: url)
                    }
                    isNavigatingToMap = true
                },
                secondaryButton: .cancel(Text("Cancelar")) {
                    isNavigatingToMap = true
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
    
    // MARK: - Métodos
    
    /**
     Navega de vuelta a la vista del mapa.
     Se llama después de que el usuario decide qué hacer con el video grabado.
     */
    func navigateToMap() {
        presentationMode.wrappedValue.dismiss()
    }

    /**
     Bloquea la orientación de la aplicación.
     Útil para mantener la vista en orientación horizontal mientras está activa
     y luego restaurar las orientaciones permitidas al salir.
     
     - Parameter orientation: Máscara de orientaciones permitidas
     */
    func lockOrientation(_ orientation: UIInterfaceOrientationMask) {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.orientationLock = orientation
        }
    }
}
