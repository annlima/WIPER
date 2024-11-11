import AVFoundation
import Photos
import SwiftUI
import Vision
import WeatherKit
import CoreLocation
import Combine

class CameraViewModel: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureFileOutputRecordingDelegate, AVCaptureDepthDataOutputDelegate {
    @Published var isRecording: Bool = false
    @Published var recordedURLs: [URL] = []
    @Published var previewUrl: URL?
    @Published var showSaveDialog: Bool = false
    @Published var detections: [CGRect] = [] // Almacena las bounding boxes de los objetos detectados
    @Published var detectedDistances: [Double] = []
    private var model: VNCoreMLModel
    
    @Published var currentWeatherCond: String?
    @ObservedObject var locationManager = LocationManager()
    private let weatherService = WeatherService.shared
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        guard let model = try? VNCoreMLModel(for: yolov5s().model) else {
            fatalError("No se pudo cargar el modelo ML")
        }
        self.model = model
        super.init()
        observeLocationUpdates()
    }
    
    // Observe lastCLLocation updates to fetch weather
    private func observeLocationUpdates() {
        locationManager.$lastLocation
            .compactMap { $0 }
            .sink { [weak self] location in
                self?.fetchCurrentWeather(for: location)
            }
            .store(in: &cancellables)
    }
    
    // Fetch weather condition using WeatherKit
    private func fetchCurrentWeather(for location: CLLocation) {
        Task {
            do {
                let weather = try await weatherService.weather(for: location)
                DispatchQueue.main.async {
                    // Directly assign the weather condition description
                    self.currentWeatherCond = weather.currentWeather.condition.description
                    print("Current Condition: \(self.currentWeatherCond ?? "Unknown")")
                }
            } catch {
                print("Failed to fetch weather data: \(error.localizedDescription)")
            }
        }
    }

    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print("Error al finalizar la grabación: \(error.localizedDescription)")
            self.isRecording = false // Actualiza el estado correctamente
            return
        }
        
        print("Video guardado en: \(outputFileURL)")
        self.recordedURLs.append(outputFileURL)
        self.previewUrl = outputFileURL
        self.showSaveDialog = true
        self.isRecording = false // Actualiza el estado correctamente
    }
    
    
    
    func saveVideoToGallery(url: URL) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            switch status {
            case .authorized, .limited:
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
                }) { success, error in
                    DispatchQueue.main.async {
                        if success {
                            print("Video guardado en la galería")
                        } else {
                            print("Error al guardar el video en la galería: \(String(describing: error))")
                        }
                    }
                }
            case .denied, .restricted:
                print("Permiso de acceso a la galería denegado")
            case .notDetermined:
                print("Permiso de acceso a la galería no determinado")
            @unknown default:
                print("Estado de permiso de galería desconocido")
            }
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard isRecording, let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        let request = VNCoreMLRequest(model: model) { (request, error) in
            if let results = request.results as? [VNRecognizedObjectObservation] {
                self.handleDetections(results)
            }
        }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try? handler.perform([request])
    }
    
    private func handleDetections(_ results: [VNRecognizedObjectObservation]) {
        DispatchQueue.main.async {
            self.detections = results.compactMap { observation in
                guard let label = observation.labels.first?.identifier,
                      ["bus", "train", "car", "truck", "motorcycle", "bicycle", "person", "dog"].contains(label) else {
                    return nil
                }
                
                // Convert bounding box to CGRect
                let boundingBox = observation.boundingBox
                let viewWidth = UIScreen.main.bounds.width
                let viewHeight = UIScreen.main.bounds.height

                let x = boundingBox.minX * viewWidth
                let y = (1 - boundingBox.maxY) * viewHeight
                let width = boundingBox.width * viewWidth
                let height = boundingBox.height * viewHeight

                return CGRect(x: x, y: y, width: width, height: height)
            }
        }
    }
}
