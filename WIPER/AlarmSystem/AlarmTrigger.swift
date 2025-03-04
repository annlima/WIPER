import AVFoundation
import UIKit
import CoreLocation

/**
 Sistema que determina cuando se debe activar una alarma basada en la distancia de frenado.
 Considera la velocidad del vehículo, la distancia al objeto detectado y las condiciones de la carretera.
 */
struct AlarmSystem {
    // MARK: - Propiedades
    
    /// Indica si se ha detectado un objeto que representa un posible riesgo
    var objectDetected: Bool
    
    /// Distancia estimada al objeto detectado en metros
    var objectDistance: Double
    
    /// Velocidad actual del vehículo en km/h
    var currentSpeed: Double
    
    /// Estimación de la visibilidad actual en metros (por debajo de umbral = carretera húmeda)
    var visibility: Double
    
    /// Tabla de distancias de frenado en metros para diferentes velocidades y condiciones
    let stoppingDistances: [Int: [String: Double]] = [
        40: ["dry": 26, "wet": 30],
        50: ["dry": 35, "wet": 40],
        60: ["dry": 45, "wet": 50],
        70: ["dry": 56, "wet": 60],
        80: ["dry": 69, "wet": 75],
        90: ["dry": 83, "wet": 90],
        100: ["dry": 98, "wet": 105],
        110: ["dry": 113, "wet": 125]
    ]
    
    /// Umbral de visibilidad para determinar si la carretera está húmeda o seca
    let visibilityThreshold: Double = 100.0
    
    // MARK: - Métodos
    
    /// Obtiene la distancia de frenado para una velocidad y condición específicas
    func getStoppingDistance(forSpeed speed: Int, condition: String) -> Double? {
        return stoppingDistances[speed]?[condition]
    }
    
    /// Encuentra la velocidad más cercana en la tabla de distancias de frenado
    func getClosestSpeedKey(forSpeed speed: Int) -> Int? {
        let availableSpeeds = Array(stoppingDistances.keys).sorted()
        return availableSpeeds.min(by: { abs($0 - speed) < abs($1 - speed) })
    }
    
    /// Determina si se debe activar la alarma basado en todos los factores
    func shouldTriggerAlarm() -> Bool {
        guard objectDetected else {
            print("No hay objeto detectado")
            return false
        }
        
        print("=== DIAGNÓSTICO DE ALARMA ===")
        print("Objeto detectado: Sí")
        print("Distancia al objeto: \(String(format: "%.2f", objectDistance)) metros")
        print("Velocidad actual: \(String(format: "%.1f", currentSpeed)) km/h")
        
        // No activar alarma si la velocidad es baja
        if currentSpeed < 15 {
            print("Velocidad por debajo del umbral (15 km/h) - No se activará alarma")
            return false
        }
        
        // Determinar condición de la carretera
        let condition = (visibility < visibilityThreshold) ? "wet" : "dry"
        print("Condición de carretera determinada: \(condition)")
        
        // Redondear la velocidad al múltiplo de 10 más cercano
        let roundedSpeed = Int((currentSpeed / 10).rounded() * 10)
        print("Velocidad redondeada: \(roundedSpeed) km/h")
        
        // Obtener distancia de frenado
        guard let closestSpeed = getClosestSpeedKey(forSpeed: roundedSpeed),
              let stoppingDistance = getStoppingDistance(forSpeed: closestSpeed, condition: condition) else {
            print("Error: No se pudo determinar distancia de frenado para \(roundedSpeed) km/h en condición \(condition)")
            return false
        }
        
        print("Velocidad de referencia: \(closestSpeed) km/h")
        print("Distancia de frenado calculada: \(stoppingDistance) metros")
        print("Criterio de alarma: Distancia al objeto (\(String(format: "%.2f", objectDistance)) m) <= Distancia de frenado (\(stoppingDistance) m)")
        
        // Determinar si se debe activar la alarma
        let shouldAlarm = objectDistance <= stoppingDistance
        print("Decisión final de alarma: \(shouldAlarm ? "ACTIVAR" : "NO ACTIVAR")")
        print("===================")
        return shouldAlarm
    }
}

/**
 Configura la sesión de audio para la reproducción de alarmas
 */
func configureAudioSessionForPlayback() {
    print("Configurando sesión de audio...")
    let audioSession = AVAudioSession.sharedInstance()
    
    do {
        try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try audioSession.setActive(true)
        print("✅ Sesión de audio configurada correctamente")
    } catch {
        print("❌ ERROR al configurar la sesión de audio: \(error)")
    }
}

/**
 Gestor centralizado para la reproducción de alarmas sonoras.
 Incluye mecanismos para evitar la reproducción excesiva de alarmas
 y sistemas de respaldo en caso de error.
 */
class AlarmManager: NSObject, AVAudioPlayerDelegate {
    // MARK: - Propiedades
    
    /// Instancia compartida (singleton)
    static let shared = AlarmManager()
    
    /// Reproductor de audio para las alarmas
    private var audioPlayer: AVAudioPlayer?
    
    /// Timestamp de la última reproducción de alarma
    private var lastAlarmTime: Date?
    
    /// Tiempo mínimo entre alarmas consecutivas (en segundos)
    private let minTimeBetweenAlarms: TimeInterval = 3.0
    
    /// Indica si actualmente se está reproduciendo un sonido de alarma
    private(set) var isPlayingAlarm = false
    
    // MARK: - Métodos
    
    /// Constructor privado para patrón singleton
    private override init() {
        super.init()
    }
    
    /**
     Reproduce el sonido de alarma si ha pasado suficiente tiempo desde la última reproducción.
     Incluye mecanismos de diagnóstico y respaldo.
     */
    func emitAlarmSound() {
        // Evitar múltiples alarmas en sucesión rápida
        if let lastTime = lastAlarmTime,
           Date().timeIntervalSince(lastTime) < minTimeBetweenAlarms {
            print("Ignorando activación de alarma - demasiado pronto desde la última")
            return
        }
        
        // Actualizar timestamp de última alarma
        lastAlarmTime = Date()
        
        print("Buscando archivo de sonido de alarma...")
        
        // Verificar existencia del archivo de sonido
        guard let soundURL = Bundle.main.url(forResource: "alarm_sound", withExtension: "mp3") else {
            print("ERROR: Archivo de sonido 'alarm_sound.mp3' no encontrado en el bundle")
            AudioServicesPlaySystemSound(1005) // Sonido de alerta del sistema
            return
        }
        
        print("Archivo de sonido encontrado en: \(soundURL)")
        
        do {
            // Preparar reproductor de audio
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.volume = 1.0 // Volumen máximo
            
            guard let player = audioPlayer else {
                print("ERROR: No se pudo inicializar AVAudioPlayer")
                AudioServicesPlaySystemSound(1005)
                return
            }
            
            // Añadir un callback para cuando termine la reproducción
            player.delegate = self
            
            print("Reproduciendo sonido de alarma...")
            isPlayingAlarm = true
            let playbackStarted = player.play()
            
            if playbackStarted {
                print("Reproducción de alarma iniciada correctamente")
            } else {
                print("ERROR: La reproducción no pudo iniciarse")
                isPlayingAlarm = false
                AudioServicesPlaySystemSound(1005)
            }
        } catch {
            print("ERROR al crear o reproducir AVAudioPlayer: \(error)")
            isPlayingAlarm = false
            AudioServicesPlaySystemSound(1005)
        }
    }
    
    /**
     Detiene cualquier alarma que esté reproduciéndose actualmente
     */
    func stopAlarm() {
        guard isPlayingAlarm, let player = audioPlayer else { return }
        player.stop()
        isPlayingAlarm = false
        print("Alarma detenida manualmente")
    }
    
    // MARK: - AVAudioPlayerDelegate
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlayingAlarm = false
        print("Reproducción de alarma finalizada")
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        isPlayingAlarm = false
        print("Error de decodificación de audio: \(error?.localizedDescription ?? "desconocido")")
        AudioServicesPlaySystemSound(1005)
    }
}

/**
 Verifica la presencia y validez del archivo de sonido de alarma en el bundle.
 Útil para diagnóstico durante el inicio de la aplicación.
 */
func checkAlarmSoundFile() {
    print("🔍 Comprobando archivo de sonido 'alarm_sound.mp3':")
    
    if let soundURL = Bundle.main.url(forResource: "alarm_sound", withExtension: "mp3") {
        print("ÉXITO: Archivo encontrado en \(soundURL)")
        
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: soundURL.path)
            let fileSize = attributes[.size] as? UInt64 ?? 0
            print("   - Tamaño del archivo: \(fileSize) bytes")
            
            if fileSize == 0 {
                print("ADVERTENCIA: El archivo existe pero está vacío")
            }
        } catch {
            print("ADVERTENCIA: El archivo existe pero no se pudo leer: \(error)")
        }
    } else {
        print("ERROR: Archivo 'alarm_sound.mp3' NO ENCONTRADO en el bundle")
        print("   Posibles soluciones:")
        print("   1. Verifica que el archivo esté incluido en el 'Copy Bundle Resources'")
        print("   2. Asegúrate de que el nombre del archivo sea exactamente 'alarm_sound.mp3'")
        print("   3. Intenta limpiar el proyecto (Clean Build Folder) y volver a construir")
    }
    
    // Buscar archivos de audio alternativos en el bundle
    print("\n🔍 Buscando archivos de audio alternativos en el bundle:")
    let fileTypes = ["mp3", "wav", "aac", "m4a"]
    var foundAnyAudioFile = false
    
    for fileType in fileTypes {
        if let urls = Bundle.main.urls(forResourcesWithExtension: fileType, subdirectory: nil), !urls.isEmpty {
            print("Encontrados \(urls.count) archivos .\(fileType):")
            for url in urls {
                print("   - \(url.lastPathComponent)")
            }
            foundAnyAudioFile = true
        }
    }
    
    if !foundAnyAudioFile {
        print("No se encontraron archivos de audio en el bundle")
    }
}

/**
 Evalúa si se debe activar una alarma basada en los parámetros actuales.
 Esta función sirve como punto de entrada principal al sistema de alarma.
 
 - Parameters:
   - objectDetected: Indica si se ha detectado un objeto de riesgo
   - objectDistance: Distancia al objeto en metros
   - locationManager: Gestor de ubicación que proporciona la velocidad
   - visibility: Visibilidad actual en metros (valor por defecto = 100.0)
 */
func checkAndTriggerAlarm(objectDetected: Bool, objectDistance: Double, locationManager: LocationManager, visibility: Double = 100.0) {
    // Asegurar un valor válido para visibilidad
    let actualVisibility = visibility > 0 ? visibility : 100.0
    
    // Obtener velocidad actual
    let speed = locationManager.speed
    
    print("\n----- Evaluando necesidad de alarma -----")
    print("Objeto detectado a: \(String(format: "%.2f", objectDistance)) metros")
    print("Velocidad actual: \(String(format: "%.1f", speed)) km/h")
    print("Visibilidad determinada: \(String(format: "%.1f", actualVisibility)) metros")
    
    // Crear y evaluar el sistema de alarma
    let alarmSystem = AlarmSystem(
        objectDetected: objectDetected,
        objectDistance: objectDistance,
        currentSpeed: speed,
        visibility: actualVisibility
    )
    
    if alarmSystem.shouldTriggerAlarm() {
        print("ALARMA ACTIVADA: Objeto a \(String(format: "%.2f", objectDistance)) metros con velocidad \(String(format: "%.1f", speed)) km/h")
        configureAudioSessionForPlayback()
        AlarmManager.shared.emitAlarmSound()
    } else {
        print("✓ Alarma no activada: Condiciones no cumplen criterios")
    }
    print("---------------------------------------\n")
}

/**
 Función para inicializar y probar el sistema de alarma durante el arranque de la aplicación.
 */
func setupAndTestAlarmSystem() {
    print("\n====== DIAGNÓSTICO DEL SISTEMA DE ALARMA ======")
    checkAlarmSoundFile()
    
    // Configurar y probar la sesión de audio
    configureAudioSessionForPlayback()
    
    // Verificar que el sistema de vibración funciona
    let generator = UIImpactFeedbackGenerator(style: .heavy)
    generator.prepare()
    generator.impactOccurred()
    print("Sistema de vibración verificado")
    
    print("Sistema de alarma inicializado correctamente")
    print("=============================================\n")
}
