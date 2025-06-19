//
//  CameraManager.swift
//  WIPER
//
//  Created by Andrea Lima Blanca on 24/09/24.
//

import AVFoundation
import SwiftUI

/**
 Gestor que administra la sesión de captura de video y su configuración.
 Se encarga de ajustar parámetros según el rendimiento del dispositivo,
 administrar la grabación y configurar las entradas y salidas de captura.
 */
class CameraManager: NSObject, ObservableObject {
    // MARK: - Propiedades publicadas
    
    /// Sesión de captura principal que coordina entradas y salidas
    @Published var session = AVCaptureSession()
    
    /// Indica si ocurrió un error de permisos
    @Published var alert = false
    
    /// Indica si la sesión de captura está ejecutándose
    @Published var isSessionRunning = false
    
    // MARK: - Propiedades
    
    /// Salida de datos de video para detección de objetos
    var videoDataOutput = AVCaptureVideoDataOutput()
    
    /// Salida para grabación de video
    var output = AVCaptureMovieFileOutput()
    
    /// Indica si la sesión ya ha sido configurada
    private var isConfigured = false
    
    // MARK: - Enumeraciones
    
    /**
     Niveles de rendimiento del dispositivo para ajustar la configuración.
     Permite optimizar el uso de recursos según la capacidad del dispositivo.
     */
    enum DevicePerformanceLevel {
        /// Dispositivos con recursos limitados (iPhone XR, iPhone 11, iPhone SE)
        case low
        /// Dispositivos con recursos moderados (iPhone 12, iPhone 13)
        case medium
        /// Dispositivos de alta gama (iPhone 14, iPhone 15, iPhone 16)
        case high
    }
    
    /// Nivel de rendimiento del dispositivo actual
    private var devicePerformanceLevel: DevicePerformanceLevel = .medium
    
    // MARK: - Métodos de grabación
    
    /**
     Inicia la grabación de video desde la cámara.
     
     - Parameter cameraViewModel: ViewModel que recibirá notificaciones sobre la grabación
     */
    func startRecording(cameraViewModel: CameraViewModel) {
        guard session.isRunning else {
            print("La sesión no está activa")
            return
        }
        
        if output.isRecording {
            print("Ya está grabando")
            return
        }
        
        // Crear URL temporal para almacenar el video
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(UUID().uuidString).mov")
        print("Intentando iniciar la grabación en: \(tempURL)")
        
        // Iniciar grabación y notificar al ViewModel
        output.startRecording(to: tempURL, recordingDelegate: cameraViewModel)
        cameraViewModel.isRecording = true
        print("Iniciando grabación en: \(tempURL)")
    }
    
    /**
     Detiene la grabación de video en curso.
     
     - Parameter cameraViewModel: ViewModel que recibirá notificaciones sobre la grabación
     */
    func stopRecording(cameraViewModel: CameraViewModel) {
        guard output.isRecording else {
            print("No hay ninguna grabación en curso para detener.")
            return
        }
        
        output.stopRecording()
        cameraViewModel.isRecording = false
        print("Grabación detenida.")
    }
    
    // MARK: - Configuración de sesión
    
    /**
     Configura la sesión de captura según el dispositivo.
     Solicita permisos y ajusta parámetros de rendimiento.
     
     - Parameters:
        - cameraViewModel: ViewModel que procesará los fotogramas capturados
        - completion: Closure para notificar si la configuración fue exitosa
     */
    func setUp(cameraViewModel: CameraViewModel, completion: @escaping (Result<Void, Error>) -> Void) {
        guard !isConfigured else {
            completion(.success(()))
            return
        }
        
        // Determinar nivel de rendimiento del dispositivo
        determineDevicePerformanceLevel()
        
        // Solicitar permiso de acceso a la cámara
        AVCaptureDevice.requestAccess(for: .video) { status in
            if status {
                DispatchQueue.main.async {
                    do {
                        // Configurar sesión según nivel de rendimiento
                        self.configureSessionBasedOnPerformance(cameraViewModel: cameraViewModel)
                        self.isConfigured = true
                        
                        // Iniciar la sesión en un hilo secundario para no bloquear la UI
                        DispatchQueue.global(qos: .userInitiated).async {
                            self.session.startRunning()
                            
                            DispatchQueue.main.async {
                                self.isSessionRunning = true
                                completion(.success(()))
                            }
                        }
                    } 
                }
            } else {
                DispatchQueue.main.async {
                    self.alert = true
                }
            }
        }
    }
    
    /**
     Determina el nivel de rendimiento del dispositivo según su modelo.
     Esto permite aplicar configuraciones optimizadas según la capacidad del hardware.
     */
    private func determineDevicePerformanceLevel() {
        let deviceModel = DeviceManager.shared.deviceModel
        
        if deviceModel.contains("iPhone XR") || deviceModel.contains("iPhone 11") || deviceModel.contains("iPhone SE") {
            devicePerformanceLevel = .low
            print("Nivel de rendimiento del dispositivo: BAJO")
        } else if deviceModel.contains("iPhone 12") || deviceModel.contains("iPhone 13") {
            devicePerformanceLevel = .medium
            print("Nivel de rendimiento del dispositivo: MEDIO")
        } else if deviceModel.contains("iPhone 14") || deviceModel.contains("iPhone 15") || deviceModel.contains("iPhone 16") {
            devicePerformanceLevel = .high
            print("Nivel de rendimiento del dispositivo: ALTO")
        } else {
            // Dispositivo no identificado - configuración conservadora
            devicePerformanceLevel = .medium
            print("Nivel de rendimiento del dispositivo: MEDIO (por defecto)")
        }
    }
    
    /**
     Configura la sesión de captura basándose en el nivel de rendimiento detectado.
     Aplica ajustes específicos para optimizar el rendimiento según el dispositivo.
     
     - Parameter cameraViewModel: ViewModel que procesará los fotogramas capturados
     */
    private func configureSessionBasedOnPerformance(cameraViewModel: CameraViewModel) {
        session.beginConfiguration()
        
        // Configuración común: input de cámara
        guard let cameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let cameraInput = try? AVCaptureDeviceInput(device: cameraDevice) else {
            print("Error al obtener dispositivo de cámara o crear input")
            return
        }
        
        if session.canAddInput(cameraInput) {
            session.addInput(cameraInput)
        }
        
        // Configuración específica según nivel de rendimiento
        switch devicePerformanceLevel {
        case .low:
            configureLowPerformanceSession(cameraDevice: cameraDevice, cameraViewModel: cameraViewModel)
        case .medium:
            configureMediumPerformanceSession(cameraDevice: cameraDevice, cameraViewModel: cameraViewModel)
        case .high:
            configureHighPerformanceSession(cameraDevice: cameraDevice, cameraViewModel: cameraViewModel)
        }
        
        // Configurar output para grabación
        if session.canAddOutput(output) {
            session.addOutput(output)
        } else {
            print("No se pudo agregar 'output' a la sesión")
        }
        
        session.commitConfiguration()
    }
    
    /**
     Configura la sesión para dispositivos de bajo rendimiento.
     Prioriza la estabilidad y eficiencia sobre la calidad visual.
     
     - Parameters:
        - cameraDevice: Dispositivo de cámara a configurar
        - cameraViewModel: ViewModel que procesará los fotogramas
     */
    private func configureLowPerformanceSession(cameraDevice: AVCaptureDevice, cameraViewModel: CameraViewModel) {
        print("Aplicando configuración para dispositivos de bajo rendimiento")
        
        // Configurar VideoDataOutput con descarte de fotogramas tardíos
        videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        videoDataOutput.setSampleBufferDelegate(cameraViewModel, queue: DispatchQueue(label: "videoQueue"))
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        
        if session.canAddOutput(videoDataOutput) {
            session.addOutput(videoDataOutput)
        }
        
        // Usar resolución media para ahorrar procesamiento
        if session.canSetSessionPreset(.medium) {
            session.sessionPreset = .medium
        }
        
        // Limitar tasa de fotogramas para reducir carga (20 FPS)
        try? cameraDevice.lockForConfiguration()
        if cameraDevice.activeFormat.videoSupportedFrameRateRanges.first?.maxFrameRate ?? 30 > 20 {
            cameraDevice.activeVideoMinFrameDuration = CMTime(value: 1, timescale: 20) // 20 FPS
        }
        cameraDevice.unlockForConfiguration()
        
        // No agregar depth output para dispositivos de bajo rendimiento
    }
    
    /**
     Configura la sesión para dispositivos de rendimiento medio.
     Busca un equilibrio entre calidad y rendimiento.
     
     - Parameters:
        - cameraDevice: Dispositivo de cámara a configurar
        - cameraViewModel: ViewModel que procesará los fotogramas
     */
    private func configureMediumPerformanceSession(cameraDevice: AVCaptureDevice, cameraViewModel: CameraViewModel) {
        print("Aplicando configuración para dispositivos de rendimiento medio")
        
        // Configurar VideoDataOutput
        videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        videoDataOutput.setSampleBufferDelegate(cameraViewModel, queue: DispatchQueue(label: "videoQueue"))
        
        if session.canAddOutput(videoDataOutput) {
            session.addOutput(videoDataOutput)
        }
        
        // Usar resolución alta pero no máxima
        if session.canSetSessionPreset(.high) {
            session.sessionPreset = .high
        }
        
        // Configurar tasa de fotogramas estándar (30 FPS)
        try? cameraDevice.lockForConfiguration()
        if cameraDevice.activeFormat.videoSupportedFrameRateRanges.first?.maxFrameRate ?? 30 > 30 {
            cameraDevice.activeVideoMinFrameDuration = CMTime(value: 1, timescale: 30) // 30 FPS
        }
        cameraDevice.unlockForConfiguration()
        
        // Agregar depth output si está disponible
        let depthAdded = cameraViewModel.addDepthOutput(to: session)
                
        if depthAdded && DeviceManager.shared.deviceHasLiDAR() {
            print("Sensor LiDAR detectado en dispositivo de gama media: habilitando funciones avanzadas")
        }
    }
    
    /**
     Configura la sesión para dispositivos de alto rendimiento.
     Maximiza la calidad visual y tasa de fotogramas.
     
     - Parameters:
        - cameraDevice: Dispositivo de cámara a configurar
        - cameraViewModel: ViewModel que procesará los fotogramas
     */
    private func configureHighPerformanceSession(cameraDevice: AVCaptureDevice, cameraViewModel: CameraViewModel) {
        print("Aplicando configuración para dispositivos de alto rendimiento")
        
        // Configurar VideoDataOutput con máxima calidad
        videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        videoDataOutput.setSampleBufferDelegate(cameraViewModel, queue: DispatchQueue(label: "videoQueue"))
        
        if session.canAddOutput(videoDataOutput) {
            session.addOutput(videoDataOutput)
        }
        
        // Usar resolución alta
        if session.canSetSessionPreset(.high) {
            session.sessionPreset = .high
        }
        
        // Permitir mayor tasa de fotogramas si es posible (hasta 60 FPS)
        try? cameraDevice.lockForConfiguration()
        let maxFrameRate = cameraDevice.activeFormat.videoSupportedFrameRateRanges.first?.maxFrameRate ?? 30
        if maxFrameRate > 30 {
            let targetFrameRate: CMTimeScale = 60 // Intentar llegar a 60 FPS si es posible
            let adjustedFrameRate = min(CMTimeScale(maxFrameRate), targetFrameRate)
            cameraDevice.activeVideoMinFrameDuration = CMTime(value: 1, timescale: adjustedFrameRate)
        }
        cameraDevice.unlockForConfiguration()
        
        // Agregar depth output con máxima calidad
        let depthAdded = cameraViewModel.addDepthOutput(to: session)
               
        if depthAdded && DeviceManager.shared.deviceHasLiDAR() {
            print("Sensor LiDAR activado: las estimaciones de distancia serán más precisas")
            
            // En dispositivos con LiDAR, podemos intentar optimizar aún más
            if let infraredDevice = AVCaptureDevice.default(.builtInTrueDepthCamera, for: .video, position: .back) {
                do {
                    let infraredInput = try AVCaptureDeviceInput(device: infraredDevice)
                    if session.canAddInput(infraredInput) {
                        session.addInput(infraredInput)
                        print("Sensor infrarrojo auxiliar añadido para mejorar datos de profundidad")
                    }
                } catch {
                    print("No se pudo añadir entrada infrarroja: \(error.localizedDescription)")
                }
            }
        }
    }
}
