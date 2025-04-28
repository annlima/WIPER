import SwiftUI
import AVFoundation
import MapKit // Import MapKit

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
    @ObservedObject var locationManager = LocationManager() // For Speed Overlay
    @State private var isNavigatingToMap = false
    // Removed @State speed as it uses locationManager directly

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
                }

            SpeedOverlayView(speed: $locationManager.speed)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                .padding(.leading, 20) // Add specific padding
                .padding(.bottom, 30)

            ForEach(cameraViewModel.detections, id: \.self) { rect in
                Rectangle()
                    .path(in: rect)
                    .stroke(Color.red, lineWidth: 2)
                    .background(Rectangle().fill(Color.clear)) // Ensure background is clear
            }

            if let route = cameraViewModel.currentRoute, !cameraViewModel.currentInstruction.isEmpty {
                 VStack(alignment: .leading, spacing: 3) {
                     Text(formatDistance(cameraViewModel.distanceToNextManeuver))
                         .font(.system(size: 18, weight: .bold)) // Reduced size
                         .foregroundColor(.white)

                     Text(cameraViewModel.currentInstruction)
                          .font(.system(size: 22, weight: .semibold)) // Reduced size
                         .foregroundColor(.white)
                         .lineLimit(2)
                         .minimumScaleFactor(0.7)
                         .fixedSize(horizontal: false, vertical: true) // Allow vertical expansion
                 }
                 .padding(.horizontal, 10) // Reduced padding
                 .padding(.vertical, 6) // Reduced padding
                 .background(Color.black.opacity(0.7))
                 .cornerRadius(8) // Slightly smaller radius
                 .shadow(radius: 2)
                 // --- POSITIONING CHANGES --
                 .frame(
                    maxWidth: UIScreen.main.bounds.width * 0.5, // Limit width (e.g., 50% of screen)
                    maxHeight: .infinity, // Allow height to adjust
                    alignment: .topLeading // Align the frame itself
                 )
                 .padding(.leading, 20) // Padding from left edge
                 .padding(.top, 40) // Padding from top edge (adjust as needed for safe area/notch)

            }
            
            VStack {
                // Close Button
                HStack {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Text("Cerrar")
                            .padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)) // Adjust padding
                            .background(Color.black.opacity(0.7))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    Spacer() // Pushes button to the left
                }
                .padding(.leading, 20) // Match instruction padding
                .padding(.top, 40) // Match instruction padding

                Spacer() // Pushes record button down

                // Record Button
                HStack {
                    Spacer() // Pushes button to the right
                    Button(action: {
                        if cameraViewModel.isRecording {
                            cameraManager.stopRecording(cameraViewModel: cameraViewModel)
                        } else {
                            cameraManager.startRecording(cameraViewModel: cameraViewModel)
                        }
                    }) {
                        Image(systemName: cameraViewModel.isRecording ? "stop.circle.fill" : "record.circle") // Use filled stop icon
                            .resizable()
                            .frame(width: 65, height: 65) // Slightly smaller
                            .foregroundColor(cameraViewModel.isRecording ? .red : .white)
                           // .padding() // Remove default padding if needed
                    }
                    .disabled(!cameraManager.isSessionRunning)
                }
                .padding(.trailing, 20) // Padding from right edge
                .padding(.bottom, 30) // Padding from bottom edge
            } // End Controls VStack

        } // End ZStack
        .alert(isPresented: $cameraViewModel.showSaveDialog) {
            Alert(
                title: Text("Guardar video"),
                message: Text("¿Deseas guardar el video en la galería?"),
                primaryButton: .default(Text("Guardar")) {
                    if let url = cameraViewModel.previewUrl { cameraViewModel.saveVideoToGallery(url: url) }
                    isNavigatingToMap = true // Still navigate back after choice
                },
                secondaryButton: .cancel(Text("Descartar")) { // Changed text for clarity
                     // Optionally delete the temporary file if discarded
                     if let url = cameraViewModel.previewUrl { try? FileManager.default.removeItem(at: url)}
                    isNavigatingToMap = true // Still navigate back
                }
            )
        }
        .onChange(of: isNavigatingToMap) { navigate in
            if navigate {
                navigateToMap()
                isNavigatingToMap = false // Reset flag
            }
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Methods

    /// Navigates back (dismisses the current view).
    func navigateToMap() {
        presentationMode.wrappedValue.dismiss()
    }

    /// Locks/Unlocks screen orientation.
    func lockOrientation(_ orientation: UIInterfaceOrientationMask) {
        // (Implementation remains the same)
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.orientationLock = orientation
        }
    }

    /// Formats distance for display.
    private func formatDistance(_ distance: CLLocationDistance) -> String {
        guard distance.isFinite && distance >= 0 else { return "-- m" } // Show placeholder

        let measurement = Measurement(value: distance, unit: UnitLength.meters) // Use UnitLength.meters
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .providedUnit // Use .providedUnit, we'll handle conversion manually
        formatter.numberFormatter.maximumFractionDigits = 0 // Default to 0 decimal places for meters

        // Decide whether to display in meters or kilometers
        if distance >= 1000 {
            // Convert to kilometers
            let measurementInKm = measurement.converted(to: UnitLength.kilometers) // Use UnitLength.kilometers
            formatter.numberFormatter.maximumFractionDigits = 1 // Allow one decimal for km
            if measurementInKm.value < 0.1 {
                 return "En \(formatter.string(from: Measurement(value: 0.1, unit: UnitLength.kilometers)))"
            } else {
                 return "En \(formatter.string(from: measurementInKm))"
            }

        } else {
            // Display in meters
            var roundedMeasurement = measurement
            if distance >= 50 {
                let roundedValue = (distance / 10).rounded() * 10
                roundedMeasurement = Measurement(value: roundedValue, unit: UnitLength.meters) // Use UnitLength.meters
            }
            // Ensure very small distances show as integer meters
            formatter.numberFormatter.maximumFractionDigits = 0
            return "En \(formatter.string(from: roundedMeasurement))"
        }
    }
}
