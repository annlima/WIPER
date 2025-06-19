import SwiftUI
import AVFoundation
import MapKit // Import MapKit
import UIKit // Needed for UIApplication

/**
 Vista principal de cámara a pantalla completa de WIPER.
 Integra la previsualización de la cámara, detección de objetos, velocidad actual,
 instrucciones de navegación y controles para grabar videos del trayecto.
 */
struct FullScreenCameraView: View {
    // MARK: - Propiedades
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var cameraViewModel: CameraViewModel
    @ObservedObject var cameraManager: CameraManager
    @ObservedObject var locationManager: LocationManager
    @State private var isNavigatingToMap = false

    // MARK: - Vista
    var body: some View {
        ZStack {
            CameraPreview(captureSession: cameraManager.session)
                .ignoresSafeArea()
                .navigationBarHidden(true)
                .onAppear {
                    cameraManager.setUp(cameraViewModel: cameraViewModel) { result in
                        switch result {
                        case .success: print("Sesión configurada y en ejecución en FullScreenCameraView")
                        case .failure(let error): print("Error al configurar la cámara: \(error.localizedDescription)")
                        }
                    }
                    lockOrientation(.landscape)
                }
                .onDisappear {
                    lockOrientation(.all)
                    
                    if UIApplication.shared.isIdleTimerDisabled {
                         UIApplication.shared.isIdleTimerDisabled = false
                         print("Idle Timer Re-enabled on Disappear")
                    }
                   
                }

            SpeedOverlayView(speed: $locationManager.speed)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                .padding(.leading, 20)
                .padding(.bottom, 30)

            ForEach(cameraViewModel.detections, id: \.self) { rect in
                Rectangle()
                    .path(in: rect)
                    .stroke(Color.red, lineWidth: 2)
                    .background(Rectangle().fill(Color.clear))
            }

            if let route = cameraViewModel.currentRoute, !cameraViewModel.currentInstruction.isEmpty {
                 VStack(alignment: .leading, spacing: 3) {
                      Text(formatDistance(cameraViewModel.distanceToNextManeuver))
                          .font(.system(size: 18, weight: .bold))
                          .foregroundColor(.white)

                      Text(cameraViewModel.currentInstruction)
                           .font(.system(size: 22, weight: .semibold))
                          .foregroundColor(.white)
                          .lineLimit(2)
                          .minimumScaleFactor(0.7)
                          .fixedSize(horizontal: false, vertical: true)
                 }
                 .padding(.horizontal, 10)
                 .padding(.vertical, 6)
                 .background(Color.black.opacity(0.7))
                 .cornerRadius(8)
                 .shadow(radius: 2)
                 .frame(
                     maxWidth: UIScreen.main.bounds.width * 0.5,
                     maxHeight: .infinity,
                     alignment: .topLeading
                 )
                 .padding(.leading, 20)
                 .padding(.top, 40)
            }

            VStack {
                
                HStack {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Text("Cerrar")
                            .padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                            .background(Color.black.opacity(0.7))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    Spacer()
                }
                .padding(.leading, 20)
                .padding(.top, 40)

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
                        Image(systemName: cameraViewModel.isRecording ? "stop.circle.fill" : "record.circle")
                            .resizable()
                            .frame(width: 65, height: 65)
                            .foregroundColor(cameraViewModel.isRecording ? .red : .white)
                           
                    }
                    .disabled(!cameraManager.isSessionRunning)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 30)
            }

        } 
        .onChange(of: cameraViewModel.isRecording) { isRecording in
             UIApplication.shared.isIdleTimerDisabled = isRecording
             print("Idle Timer Disabled: \(isRecording)")
        }
        .alert(isPresented: $cameraViewModel.showSaveDialog) {
            Alert(
                title: Text("Guardar video"),
                message: Text("¿Deseas guardar el video en la galería?"),
                primaryButton: .default(Text("Guardar")) {
                    if let url = cameraViewModel.previewUrl { cameraViewModel.saveVideoToGallery(url: url) }
                    isNavigatingToMap = true
                },
                secondaryButton: .cancel(Text("Descartar")) {
                    
                     if let url = cameraViewModel.previewUrl {
                         do {
                             try FileManager.default.removeItem(at: url)
                         } catch {
                             print("Error deleting discarded video: \(error)")
                         }
                     }
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
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Methods

    func navigateToMap() {
        presentationMode.wrappedValue.dismiss()
    }

    func lockOrientation(_ orientation: UIInterfaceOrientationMask) {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
             windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: orientation)) { error in
                 print("Orientation lock error: \(error.localizedDescription)")
             }
         }
         if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
              appDelegate.orientationLock = orientation
         }
    }

    private func formatDistance(_ distance: CLLocationDistance) -> String {
        guard distance.isFinite && distance >= 0 else { return "-- m" }
        let measurement = Measurement(value: distance, unit: UnitLength.meters)
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .providedUnit
        formatter.numberFormatter.maximumFractionDigits = 0
        if distance >= 1000 {
           
            let measurementInKm = measurement.converted(to: UnitLength.kilometers)
            formatter.numberFormatter.maximumFractionDigits = 1
            let valueToShow = max(measurementInKm.value, 0.1)
            let finalMeasurement = Measurement(value: valueToShow, unit: UnitLength.kilometers)
            return "En \(formatter.string(from: finalMeasurement))"

        } else {
            var valueToFormat = distance
            if distance >= 50 {
                 valueToFormat = (distance / 10).rounded() * 10
            }
            formatter.numberFormatter.maximumFractionDigits = 0
            let roundedMeasurement = Measurement(value: valueToFormat, unit: UnitLength.meters)
            return "En \(formatter.string(from: roundedMeasurement))"
        }
    }
}
