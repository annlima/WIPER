//
//  CameraViewModel.swift
//  WIPER
//
//  Created by Andrea Lima Blanca on 24/09/24.
//

import AVFoundation
import Photos
import SwiftUI
import Vision
import WeatherKit
import CoreLocation
import Combine
import MapKit
/**
 ViewModel principal que gestiona la captura de video, detección de objetos,
 cálculo de distancias y activación de alarmas.
 
 Esta clase coordina todos los aspectos del procesamiento de imágenes en WIPER,
 incluyendo la mejora adaptativa de imágenes según condiciones climáticas,
 la detección basada en aprendizaje automático, y la evaluación de riesgos.
 */
class CameraViewModel: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureFileOutputRecordingDelegate, AVCaptureDepthDataOutputDelegate {
    // MARK: - Propiedades publicadas
    
    /// Indica si se está grabando video actualmente
    @Published var isRecording: Bool = false
    
    /// Lista de URLs de videos grabados durante la sesión
    @Published var recordedURLs: [URL] = []
    
    /// URL del video previamente grabado disponible para guardar
    @Published var previewUrl: URL?
    
    /// Controla la visualización del diálogo para guardar video
    @Published var showSaveDialog: Bool = false
    
    /// Rectángulos de los objetos detectados para mostrar en la UI
    @Published var detections: [CGRect] = []
    
    /// Distancias calculadas a los objetos detectados en metros
    @Published var detectedDistances: [Double] = []
    
    /// Condición climática actual proporcionada por WeatherKit
    @Published var currentWeatherCond: String?
    
    /// Indica si está en modo de prueba (para simulaciones)
    @Published var isTestMode: Bool = true
    
    // MARK: - Propiedades privadas
    
    /// Modelo CoreML para detección de objetos
    private var model: VNCoreMLModel
    
    /// Utilidad para mejorar imágenes según condiciones climáticas
    private var imageEnhancer = ImageEnhancer()
    
    /// Gestor de ubicación para obtener velocidad y posición
    @ObservedObject var locationManager = LocationManager()
    
    /// Servicio para obtener datos meteorológicos
    private let weatherService = WeatherService.shared
    
    /// Almacena suscripciones Combine para limpieza adecuada
    private var cancellables = Set<AnyCancellable>()
    
    /// Salida para datos de profundidad (disponible en dispositivos compatibles)
    private var depthOutput = AVCaptureDepthDataOutput()
    
    /// Estimación de visibilidad actual en metros
    var visibility: Double = 100.0
    
    /// Contador de fotogramas para omisión selectiva
    private var frameCount: Int = 0
    
    /// Intervalo de procesamiento de fotogramas (procesa 1 de cada N fotogramas)
    private(set) var frameProcessingInterval: Int = 3
    
    /// Marca de tiempo de la última detección realizada
    private var lastDetectionTime: Date = Date()
    
    /// Tiempo mínimo entre detecciones consecutivas (en segundos)
    private var minTimeBetweenDetections: TimeInterval = 0.1
    
    /// Tabla de alturas reales de objetos en metros (para cálculo de distancias)
    private let realObjectHeights: [String: CGFloat] = [
        "auto rickshaw": 1.5, // Altura aproximada de un auto rickshaw
        "bicycle": 1.0,       // Altura promedio de una bicicleta
        "bus": 3.2,           // Altura promedio de un autobús
        "car": 1.5,           // Altura promedio de un automóvil
        "motorbike": 1.2,     // Altura promedio de una motocicleta
        "pedestrian": 1.7,    // Altura promedio de un peatón
        "person": 1.7,        // Altura promedio de una persona
        "truck": 3.5          // Altura promedio de un camión
    ]
    
    @Published var currentInstruction: String = "Iniciando navegación..." // Initial instruction
    @Published var distanceToNextManeuver: CLLocationDistance = .infinity // Distance in meters
    @Published private(set) var currentRoute: MKRoute? // Store the route
    @Published private(set) var currentRouteStepIndex: Int = 0 // Track current step

    
    // MARK: - Inicialización
    
    init(route: MKRoute? = nil) { // Allow optional route injection
        // Load ML Model
        guard let loadedModel = try? VNCoreMLModel(for: best_yolov5s().model) else {
            fatalError("No se pudo cargar el modelo ML")
        }
        self.model = loadedModel
        self.currentRoute = route // Store the passed route
        
        super.init()
        
        observeLocationUpdates() // Start observing location
        adjustProcessingForDevice()
        
        // Initialize navigation state if route exists
        if let initialRoute = route, !initialRoute.steps.isEmpty {
            updateNavigationInstruction(stepIndex: 0) // Show the first step instruction
        } else {
            currentInstruction = "" // No route, no instruction
        }
    }
    
    
    // MARK: - Ajustes y configuración
    
    /**
     Configura el intervalo de procesamiento de fotogramas.
     Establece cada cuántos fotogramas se realiza el procesamiento para detección.
     
     - Parameter interval: Número de fotogramas a omitir entre cada procesamiento
     */
    func setFrameProcessingInterval(_ interval: Int) {
        self.frameProcessingInterval = max(1, interval) // Asegurar que sea al menos 1
        print("Configurando intervalo de procesamiento: cada \(frameProcessingInterval) fotogramas")
    }
    
    /**
     Ajusta los parámetros de procesamiento según el modelo de dispositivo.
     Los dispositivos más antiguos procesan menos fotogramas para mantener el rendimiento.
     */
    private func adjustProcessingForDevice() {
        let deviceModel = DeviceManager.shared.deviceModel
        
        // Ajustar intervalos según la capacidad del dispositivo
        if deviceModel.contains("iPhone XR") || deviceModel.contains("iPhone 11") || deviceModel.contains("iPhone SE") {
            // Dispositivos de menor rendimiento
            setFrameProcessingInterval(6)
            minTimeBetweenDetections = 0.2 // 200ms
        } else if deviceModel.contains("iPhone 12") || deviceModel.contains("iPhone 13") {
            // Dispositivos de rendimiento medio
            setFrameProcessingInterval(4)
            minTimeBetweenDetections = 0.15 // 150ms
        } else if deviceModel.contains("iPhone 14") || deviceModel.contains("iPhone 15") {
            // Dispositivos de alto rendimiento
            setFrameProcessingInterval(2)
            minTimeBetweenDetections = 0.1 // 100ms
        } else {
            // Dispositivos no identificados - configuración conservadora
            setFrameProcessingInterval(5)
            minTimeBetweenDetections = 0.15 // 150ms
        }
    }
    
                
    /**
     Configura los observadores para actualizaciones de ubicación.
     Cuando cambia la ubicación, se obtienen nuevos datos meteorológicos.
     */
    private func observeLocationUpdates() {
        locationManager.$lastLocation
            .compactMap { $0 } // Ensure we have a location
        // Throttle updates slightly if needed, e.g., .throttle(for: 1, scheduler: RunLoop.main, latest: true)
            .sink { [weak self] location in
                guard let self = self else { return }
                // Fetch weather (existing logic)
                self.fetchCurrentWeather(for: location)
                // ---- NEW: Update navigation progress ----
                self.updateNavigationProgress(userLocation: location)
            }
            .store(in: &cancellables)
    }
    
    private func updateNavigationProgress(userLocation: CLLocation) {
        guard let route = currentRoute, currentRouteStepIndex < route.steps.count else {
            // No route or navigation finished
            return
        }

        let currentStep = route.steps[currentRouteStepIndex]
        let polyline = currentStep.polyline // Get the polyline for the current step

        // --- Calculate distance to end of current step ---
        // Check if the polyline has points
        if polyline.pointCount > 0 {
            // Get pointer to the MKMapPoint array
            let mapPoints = polyline.points()
            // Get the last point and convert it to CLLocationCoordinate2D
            let lastMapPoint = mapPoints[polyline.pointCount - 1]
            let lastStepCoordinate = lastMapPoint.coordinate // Conversion happens here

            let maneuverLocation = CLLocation(latitude: lastStepCoordinate.latitude, longitude: lastStepCoordinate.longitude)
            // Calculate distance from user to the maneuver point
            let distance = userLocation.distance(from: maneuverLocation)
            DispatchQueue.main.async {
                self.distanceToNextManeuver = distance
            }
        } else {
            // Cannot calculate distance if polyline has no points
            DispatchQueue.main.async {
                self.distanceToNextManeuver = .infinity
            }
        }

        // --- Check if user has completed the current step ---
        let stepCompletionThreshold: CLLocationDistance = 30.0 // meters (adjust as needed)

        if currentRouteStepIndex + 1 < route.steps.count {
            let nextStep = route.steps[currentRouteStepIndex + 1]
            let nextPolyline = nextStep.polyline // Get the polyline for the next step

            // Check if the next polyline has points
            if nextPolyline.pointCount > 0 {
                // Get pointer to the MKMapPoint array
                let nextMapPoints = nextPolyline.points()
                // Get the first point and convert it to CLLocationCoordinate2D
                let firstNextMapPoint = nextMapPoints[0]
                let firstNextStepCoordinate = firstNextMapPoint.coordinate // Conversion

                let nextStepStartLocation = CLLocation(latitude: firstNextStepCoordinate.latitude, longitude: firstNextStepCoordinate.longitude)
                let distanceToNextStepStart = userLocation.distance(from: nextStepStartLocation)

                print("Distance to next step start: \(distanceToNextStepStart)") // Debug print

                if distanceToNextStepStart < stepCompletionThreshold {
                    // Advance to the next step
                    DispatchQueue.main.async {
                        self.advanceToNextStep()
                    }
                }
            }
        } else {
            // Handle arrival at the last step (using distanceToNextManeuver calculated above)
            if distanceToNextManeuver < stepCompletionThreshold {
                DispatchQueue.main.async {
                    self.currentInstruction = "Has llegado a tu destino."
                    self.distanceToNextManeuver = 0
                    // Consider stopping navigation state updates here
                }
            }
        }
    }
    
    private func advanceToNextStep() {
            guard let route = currentRoute, currentRouteStepIndex + 1 < route.steps.count else { return }
            currentRouteStepIndex += 1
            updateNavigationInstruction(stepIndex: currentRouteStepIndex)
            print("Advanced to step \(currentRouteStepIndex)") // Debug print
       }

        private func updateNavigationInstruction(stepIndex: Int) {
             guard let route = currentRoute, stepIndex < route.steps.count else { return }
             let step = route.steps[stepIndex]
             // Update the published instruction - might add distance later
             self.currentInstruction = step.instructions.isEmpty ? "Continúa recto" : step.instructions
        }

    /**
     Obtiene datos meteorológicos actualizados para la ubicación proporcionada.
     
     - Parameter location: Ubicación para la que se requieren los datos meteorológicos
     */
    private func fetchCurrentWeather(for location: CLLocation) {
        Task {
            do {
                let weather = try await weatherService.weather(for: location)
                DispatchQueue.main.async {
                    self.currentWeatherCond = weather.currentWeather.condition.description
                    print("Current Condition: \(self.currentWeatherCond ?? "Unknown")")
                }
            } catch {
                print("Failed to fetch weather data: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Cálculo de distancias
    
    /**
     Calcula la distancia a un objeto detectado basándose en su tamaño en la imagen.
     Utiliza la relación entre el tamaño aparente en la imagen y el tamaño real conocido.
     
     - Parameters:
       - detection: Rectángulo del objeto detectado en coordenadas de pantalla
       - objectLabel: Etiqueta del tipo de objeto detectado
     
     - Returns: Distancia estimada en metros, o nil si no se pudo calcular
     */
    func calculateDistance(for detection: CGRect, objectLabel: String) -> Double? {
        // Obtener longitud focal en milímetros desde los datos del dispositivo
        let focalLengthInMM = DeviceManager.shared.focalLength
        if focalLengthInMM == 0.0 {
            print("Warning: Focal length is zero. Skipping distance calculation for \(objectLabel).")
            return nil
        }
        
        // Buscar altura real del objeto en la tabla de referencia
        guard let realObjectHeight = realObjectHeights[objectLabel] else {
            print("Real object height for \(objectLabel) not found.")
            return nil
        }
        
        // Obtener altura del objeto en píxeles
        let imageObjectHeightPixels = detection.height
        guard imageObjectHeightPixels > 0 else {
            print("Image object height is zero.")
            return nil
        }
        
        // Convertir longitud focal a píxeles usando datos del sensor
        let sensorHeightInMM = 7.0     // Altura aproximada del sensor
        let sensorHeightInPixels = 3024.0  // Resolución vertical típica del sensor
        
        let focalLengthInPixels = (focalLengthInMM / sensorHeightInMM) * sensorHeightInPixels
        
        // Aplicar fórmula para calcular distancia
        // distancia = (altura real * longitud focal) / altura en imagen
        let distance = (realObjectHeight * focalLengthInPixels) / Double(imageObjectHeightPixels)
        
        // Factor de ajuste empírico para mejorar precisión
        let adjustedDistance = distance / 10.0
        
        print("Calculated distance for \(objectLabel): \(adjustedDistance) meters.")
        return adjustedDistance
    }
    
    // MARK: - Procesamiento de video
    
    /**
     Procesa cada fotograma recibido de la cámara para detectar objetos.
     Implementa omisión de fotogramas y preprocesamiento según clima.
     
     - Parameters:
       - output: Salida que proporciona los datos del fotograma
       - sampleBuffer: Buffer de muestra que contiene el fotograma
       - connection: Conexión asociada con la salida
     */
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard isRecording, let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        // Implementación de omisión de fotogramas
        frameCount += 1
        if frameCount % frameProcessingInterval != 0 {
            return // Omitir este fotograma
        }
        
        // Control de tiempo entre detecciones
        let currentTime = Date()
        if currentTime.timeIntervalSince(lastDetectionTime) < minTimeBetweenDetections {
            return // No ha pasado suficiente tiempo desde la última detección
        }
        lastDetectionTime = currentTime
        
        // Ajustar umbral de confianza según dispositivo
        let deviceModel = DeviceManager.shared.deviceModel
        let confidenceThreshold: Float = (deviceModel.contains("iPhone XR") || deviceModel.contains("iPhone 11")) ? 0.5 : 0.3
        
        // Crear solicitud de detección con CoreML
        let request = VNCoreMLRequest(model: model) { [weak self] (request, error) in
            guard let self = self else { return }
            
            if let results = request.results as? [VNRecognizedObjectObservation] {
                // Filtrar resultados según umbral de confianza
                let filteredResults = results.filter { observation in
                    guard let firstLabel = observation.labels.first else { return false }
                    return firstLabel.confidence >= confidenceThreshold
                }
                
                self.handleDetections(filteredResults)
            }
        }

        request.imageCropAndScaleOption = .scaleFill

        // Aplicar preprocesamiento según condición climática
        if let condition = currentWeatherCond, !condition.isEmpty {
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            let uiImage = UIImage(ciImage: ciImage)
            
            // Seleccionar filtro apropiado según condición
            let preprocessedImage: UIImage?
            switch condition.lowercased() {
            case "sunny":
                preprocessedImage = imageEnhancer.applyCLAHE(to: uiImage)
            case "fog":
                preprocessedImage = imageEnhancer.applyDehaze(to: uiImage)
            case "rain":
                preprocessedImage = imageEnhancer.applyRainRemoval(to: uiImage)
            case "night":
                preprocessedImage = imageEnhancer.applyNightEnhancement(to: uiImage)
            default:
                preprocessedImage = uiImage
            }
            
            guard let finalImage = preprocessedImage, let cgImage = finalImage.cgImage else {
                print("Error: No se pudo obtener cgImage de la imagen preprocesada")
                return
            }
            
            // Ejecutar detección sobre imagen procesada
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        } else {
            // Sin preprocesamiento cuando no hay condición climática específica
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
            try? handler.perform([request])
        }
    }
    
    /**
     Procesa los resultados de detección de objetos.
     Filtra los objetos relevantes, calcula sus posiciones en pantalla y distancias.
     
     - Parameter results: Observaciones de objetos detectados por Vision
     */
    private func handleDetections(_ results: [VNRecognizedObjectObservation]) {
        DispatchQueue.main.async {
            self.detections = results.compactMap { observation in
                // Filtrar solo clases relevantes para seguridad vial
                guard let label = observation.labels.first?.identifier,
                      ["bus", "train", "car", "truck", "motorbike", "bicycle", "person", "pedestrian"].contains(label) else {
                    return nil
                }
                
                // Convertir bounding box normalizado a coordenadas de pantalla
                let boundingBox = observation.boundingBox
                let viewWidth = UIScreen.main.bounds.width
                let viewHeight = UIScreen.main.bounds.height

                let x = boundingBox.minX * viewWidth
                let y = (1 - boundingBox.maxY) * viewHeight
                let width = boundingBox.width * viewWidth
                let height = boundingBox.height * viewHeight

                let detectionRect = CGRect(x: x, y: y, width: width, height: height)
                
                // Calcular distancia y evaluar necesidad de alarma
                if let distance = self.calculateDistance(for: detectionRect, objectLabel: label) {
                    self.detectedDistances.append(distance)
                    
                    // Verificar si es necesario activar una alarma
                    checkAndTriggerAlarm(
                        objectDetected: true,
                        objectDistance: distance,
                        locationManager: self.locationManager,
                        visibility: self.visibility
                    )
                } else {
                    print("Failed to calculate distance for \(label)")
                }

                return detectionRect
            }
        }
    }
    
    // MARK: - Gestión de datos de profundidad
    
    /**
     Agrega la salida de datos de profundidad a la sesión de captura.
     Solo disponible en dispositivos con cámara TrueDepth.
     
     - Parameter session: Sesión de captura a la que añadir la salida
     */
    /**
         Añade una salida de datos de profundidad a la sesión de captura si está disponible.
         En dispositivos con LiDAR, esto proporcionará datos de profundidad de alta precisión.
         En otros dispositivos compatibles, podría usar TrueDepth u otros métodos.
         
         - Parameter session: Sesión de captura a la que añadir la salida de profundidad
         - Returns: true si se añadió correctamente, false si no se pudo añadir
         */
    
        func addDepthOutput(to session: AVCaptureSession) -> Bool {
            // Verificar si el dispositivo tiene LiDAR
            let hasLiDAR = DeviceManager.shared.deviceHasLiDAR()
            
            if session.canAddOutput(depthOutput) {
                session.addOutput(depthOutput)
                depthOutput.isFilteringEnabled = true
                depthOutput.setDelegate(self, callbackQueue: DispatchQueue(label: "depthQueue"))
                
                if let connection = depthOutput.connection(with: .depthData) {
                    // Habilitar la conexión de datos de profundidad
                    connection.isEnabled = true
                    
                    // Configurar la orientación de video si es necesario
                    if connection.isVideoOrientationSupported {
                        connection.videoOrientation = .landscapeRight
                    }
                    
                    print("Conexión de datos de profundidad configurada correctamente")
                }
                        
                        return true
            } else {
                print("Este dispositivo no soporta captura de datos de profundidad")
                return false
            }
        }
        
        /**
         Procesa los datos de profundidad recibidos de los sensores de la cámara.
         En dispositivos con LiDAR, estos datos tendrán mayor precisión y alcance.
         
         - Parameters:
           - output: Salida que generó los datos
           - depthData: Datos de profundidad capturados
           - connection: Conexión que produjo los datos
         */
        func captureOutput(_ output: AVCaptureOutput, didOutput depthData: AVDepthData, from connection: AVCaptureConnection) {
            // Determinar la fuente de los datos de profundidad
            let hasLiDAR = DeviceManager.shared.deviceHasLiDAR()
            let dataSource = hasLiDAR ? "LiDAR" : "TrueDepth/Estéreo"
            
            print("📏 Datos de profundidad recibidos (Fuente: \(dataSource))")
            
            // Convertir a formato compatible si es necesario
            let depthDataForProcessing: AVDepthData
            let depthFormatType = kCVPixelFormatType_DepthFloat32
            
            if depthData.depthDataType != depthFormatType {
                depthDataForProcessing = depthData.converting(toDepthDataType: depthFormatType)
            } else {
                depthDataForProcessing = depthData
            }
            
            let depthPixelBuffer = depthDataForProcessing.depthDataMap
            CVPixelBufferLockBaseAddress(depthPixelBuffer, .readOnly)
            defer { CVPixelBufferUnlockBaseAddress(depthPixelBuffer, .readOnly) }

            let width = CVPixelBufferGetWidth(depthPixelBuffer)
            let height = CVPixelBufferGetHeight(depthPixelBuffer)
            guard let baseAddress = CVPixelBufferGetBaseAddress(depthPixelBuffer) else {
                print("Error: No se pudo obtener la dirección base del mapa de profundidad")
                return
            }
            
            let floatBuffer = unsafeBitCast(baseAddress, to: UnsafeMutablePointer<Float32>.self)
            print("Mapa de profundidad: \(width)x\(height) píxeles, resolución: \(hasLiDAR ? "alta" : "estándar")")

            DispatchQueue.main.async {
                // Actualizar distancias usando datos de profundidad
                self.detectedDistances = self.detections.map { detection in
                    let normalizedX = detection.midX / UIScreen.main.bounds.width
                    let normalizedY = detection.midY / UIScreen.main.bounds.height
                    let pixelX = Int(normalizedX * CGFloat(width))
                    let pixelY = Int(normalizedY * CGFloat(height))
                    
                    guard pixelX >= 0 && pixelX < width && pixelY >= 0 && pixelY < height else {
                        return Double.nan
                    }
                    
                    let index = pixelY * width + pixelX
                    let depth = Double(floatBuffer[index])
                    
                    // La confianza en los datos es mayor con LiDAR
                    let confidenceNote = hasLiDAR ? "alta precisión" : "precisión estándar"
                    print("Profundidad en (\(pixelX), \(pixelY)): \(depth) metros (\(confidenceNote))")
                    return depth
                }
                
                // Evaluar necesidad de alarmas con las distancias actualizadas
                for (index, distance) in self.detectedDistances.enumerated() where !distance.isNaN {
                    checkAndTriggerAlarm(
                        objectDetected: true,
                        objectDistance: distance,
                        locationManager: self.locationManager,
                        visibility: self.visibility
                    )
                }
            }
        }

    
    // MARK: - Grabación de video
    
    /**
     Manejador para cuando finaliza la grabación de un video.
     Actualiza el estado y prepara el diálogo para guardar.
     
     - Parameters:
       - output: Salida de archivo que generó el evento
       - outputFileURL: URL donde se guardó el archivo de video
       - connections: Conexiones asociadas con la salida
       - error: Error opcional si ocurrió algún problema
     */
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print("Error al finalizar la grabación: \(error.localizedDescription)")
            self.isRecording = false
            return
        }
        
        print("Video guardado en: \(outputFileURL)")
        self.recordedURLs.append(outputFileURL)
        self.previewUrl = outputFileURL
        self.showSaveDialog = true
        self.isRecording = false
    }
    
    /**
     Guarda un video grabado en la galería de fotos del dispositivo.
     Solicita permisos si es necesario.
     
     - Parameter url: URL del video a guardar
     */
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
}
