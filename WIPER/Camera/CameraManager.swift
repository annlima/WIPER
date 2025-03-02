// CameraManager.swift
import AVFoundation
import SwiftUI

class CameraManager: NSObject, ObservableObject {
    @Published var session = AVCaptureSession()
    @Published var alert = false
    var videoDataOutput = AVCaptureVideoDataOutput()
    var output = AVCaptureMovieFileOutput()
    @Published var isSessionRunning = false
    private var isConfigured = false
    
    enum DevicePerformanceLevel {
        case low
        case medium
        case high    
    }
    
    private var devicePerformanceLevel: DevicePerformanceLevel = .medium
       
    func startRecording(cameraViewModel: CameraViewModel) {
        guard session.isRunning else {
            print("La sesión no está activa")
            return
        }
        
        if output.isRecording {
            print("Ya está grabando")
            return
        }
        
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(UUID().uuidString).mov")
        print("Intentando iniciar la grabación en: \(tempURL)")
        output.startRecording(to: tempURL, recordingDelegate: cameraViewModel)
        cameraViewModel.isRecording = true
        print("Iniciando grabación en: \(tempURL)")
    }
    
    
    func stopRecording(cameraViewModel: CameraViewModel) {
        guard output.isRecording else {
            print("No hay ninguna grabación en curso para detener.")
            return
        }
        
        output.stopRecording()
        cameraViewModel.isRecording = false
        print("Grabación detenida.")
    }
    
    func setUp(cameraViewModel: CameraViewModel, completion: @escaping (Result<Void, Error>) -> Void) {
        guard !isConfigured else {
            completion(.success(()))
            return
        }
        
        // NUEVO: Determinar nivel de rendimiento del dispositivo
        determineDevicePerformanceLevel()
        
        AVCaptureDevice.requestAccess(for: .video) { status in
            if status {
                DispatchQueue.main.async {
                    do {
                        // NUEVO: Configurar sesión según nivel de rendimiento
                        self.configureSessionBasedOnPerformance(cameraViewModel: cameraViewModel)
                        self.isConfigured = true
                        
                        // Iniciar la sesión
                        DispatchQueue.global(qos: .userInitiated).async {
                            self.session.startRunning()
                            
                            DispatchQueue.main.async {
                                self.isSessionRunning = true
                                completion(.success(()))
                            }
                        }
                    } catch {
                        completion(.failure(error))
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.alert = true
                }
            }
        }
    }
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
        
        // NUEVO: Configuración para dispositivos de bajo rendimiento
        private func configureLowPerformanceSession(cameraDevice: AVCaptureDevice, cameraViewModel: CameraViewModel) {
            print("Aplicando configuración para dispositivos de bajo rendimiento")
            
            // Configurar VideoDataOutput
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
            
            // Limitar tasa de fotogramas para reducir carga
            try? cameraDevice.lockForConfiguration()
            if cameraDevice.activeFormat.videoSupportedFrameRateRanges.first?.maxFrameRate ?? 30 > 20 {
                cameraDevice.activeVideoMinFrameDuration = CMTime(value: 1, timescale: 20) // 20 FPS
            }
            cameraDevice.unlockForConfiguration()
            
            // No agregar depth output para dispositivos de bajo rendimiento
        }
        
        // NUEVO: Configuración para dispositivos de rendimiento medio
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
            
            // Configurar tasa de fotogramas estándar
            try? cameraDevice.lockForConfiguration()
            if cameraDevice.activeFormat.videoSupportedFrameRateRanges.first?.maxFrameRate ?? 30 > 30 {
                cameraDevice.activeVideoMinFrameDuration = CMTime(value: 1, timescale: 30) // 30 FPS
            }
            cameraDevice.unlockForConfiguration()
            
            // Agregar depth output si está disponible
            cameraViewModel.addDepthOutput(to: session)
        }
        
        // NUEVO: Configuración para dispositivos de alto rendimiento
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
        
        // Permitir mayor tasa de fotogramas si es posible
        try? cameraDevice.lockForConfiguration()
        let maxFrameRate = cameraDevice.activeFormat.videoSupportedFrameRateRanges.first?.maxFrameRate ?? 30
        if maxFrameRate > 30 {
            let targetFrameRate: CMTimeScale = 60 // Intentar llegar a 60 FPS si es posible
            let adjustedFrameRate = min(CMTimeScale(maxFrameRate), targetFrameRate)
            cameraDevice.activeVideoMinFrameDuration = CMTime(value: 1, timescale: adjustedFrameRate)
        }
        cameraDevice.unlockForConfiguration()
        
        // Agregar depth output con máxima calidad
        cameraViewModel.addDepthOutput(to: session)
        
    }
}
