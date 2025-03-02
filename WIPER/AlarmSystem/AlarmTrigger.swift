// SOLUCION 1: MODIFICACIÓN DE AlarmSystem PARA FUNCIONAR SIN WEATHERKIT

// Modificar la estructura AlarmSystem para funcionar aún sin datos de WeatherKit
struct AlarmSystem {
    var objectDetected: Bool
    var objectDistance: Double
    var currentSpeed: Double
    var visibility: Double // Este valor puede ser problemático sin WeatherKit
    
    // Predefined stopping distances (in meters) for each speed category
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
    
    let visibilityThreshold: Double = 100.0 // Threshold for good/bad visibility
    
    func getStoppingDistance(forSpeed speed: Int, condition: String) -> Double? {
        return stoppingDistances[speed]?[condition]
    }
    
    func getClosestSpeedKey(forSpeed speed: Int) -> Int? {
        let availableSpeeds = Array(stoppingDistances.keys)
        return availableSpeeds.min(by: { abs($0 - speed) < abs($1 - speed) })
    }
    
    func shouldTriggerAlarm() -> Bool {
        guard objectDetected else {
            print("No hay objeto detectado")
            return false
        }
        
        // NUEVO: Agregar más logs detallados para diagnóstico
        print("=== DIAGNÓSTICO DE ALARMA ===")
        print("Objeto detectado: Sí")
        print("Distancia al objeto: \(objectDistance) metros")
        print("Velocidad actual: \(currentSpeed) km/h")
        
        // Ignore alarm if speed is below 15 km/h
        if currentSpeed < 15 {
            print("Velocidad por debajo del umbral (15 km/h) - No se activará alarma")
            return false
        }
        
        // NUEVO: Usar valor por defecto para visibilidad si no hay datos de WeatherKit
        // Asumir condiciones secas si no hay datos de clima
        let condition = (visibility < visibilityThreshold) ? "wet" : "dry"
        print("Condición de carretera determinada: \(condition)")
        
        // Find the closest speed category
        let roundedSpeed = Int((currentSpeed / 10).rounded() * 10)
        print("Velocidad redondeada: \(roundedSpeed) km/h")
        
        guard let closestSpeed = getClosestSpeedKey(forSpeed: roundedSpeed),
              let stoppingDistance = getStoppingDistance(forSpeed: closestSpeed, condition: condition) else {
            print("Error: No se pudo determinar distancia de frenado para \(roundedSpeed) km/h en condición \(condition)")
            return false
        }
        
        print("Velocidad de referencia: \(closestSpeed) km/h")
        print("Distancia de frenado calculada: \(stoppingDistance) metros")
        print("Criterio de alarma: Distancia al objeto (\(objectDistance) m) <= Distancia de frenado (\(stoppingDistance) m)")
        
        // Trigger alarm if distance is less than or equal to stopping distance
        let shouldAlarm = objectDistance <= stoppingDistance
        print("Decisión final de alarma: \(shouldAlarm ? "ACTIVAR" : "NO ACTIVAR")")
        print("===================")
        return shouldAlarm
    }
}

// SOLUCIÓN 2: CORREGIR LA FUNCIÓN DE REPRODUCCIÓN DE AUDIO

import AVFoundation

func configureAudioSessionForPlayback() {
    print("Configurando sesión de audio...")
    let audioSession = AVAudioSession.sharedInstance()
    
    do {
        try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try audioSession.setActive(true)
        print("Sesión de audio configurada correctamente")
    } catch {
        print("ERROR al configurar la sesión de audio: \(error)")
    }
}

class AlarmManager {
    static let shared = AlarmManager()
    var audioPlayer: AVAudioPlayer?
    
    // NUEVO: Variable para rastrear tiempo de la última alarma
    private var lastAlarmTime: Date?
    // NUEVO: Tiempo mínimo entre alarmas (en segundos)
    private let minTimeBetweenAlarms: TimeInterval = 3.0
    
    func emitAlarmSound() {
        // NUEVO: Verificar si ha pasado suficiente tiempo desde la última alarma
        if let lastTime = lastAlarmTime,
           Date().timeIntervalSince(lastTime) < minTimeBetweenAlarms {
            print("Ignorando activación de alarma - demasiado pronto desde la última")
            return
        }
        
        // NUEVO: Actualizar tiempo de última alarma
        lastAlarmTime = Date()
        
        print("Buscando archivo de sonido de alarma...")
        
        // NUEVO: Verificar si el archivo existe en el bundle
        guard let soundURL = Bundle.main.url(forResource: "alarm_sound", withExtension: "mp3") else {
            print("ERROR: Archivo de sonido 'alarm_sound.mp3' no encontrado en el bundle.")
            // NUEVO: Reproducir un sonido del sistema como fallback
            AudioServicesPlaySystemSound(1005) // Este es un sonido de alerta del sistema
            return
        }
        
        print("Archivo de sonido encontrado en: \(soundURL)")
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.volume = 1.0 // Asegurar volumen máximo
            
            // NUEVO: Verificar si el audioPlayer se inicializó correctamente
            guard let player = audioPlayer else {
                print("ERROR: No se pudo inicializar AVAudioPlayer")
                AudioServicesPlaySystemSound(1005) // Usar sonido del sistema como respaldo
                return
            }
            
            print("Reproduciendo sonido de alarma...")
            let playbackStarted = player.play()
            
            if playbackStarted {
                print("Reproducción de alarma iniciada correctamente")
            } else {
                print("ERROR: La reproducción no pudo iniciarse")
                AudioServicesPlaySystemSound(1005) // Usar sonido del sistema como respaldo
            }
        } catch {
            print("ERROR al crear o reproducir AVAudioPlayer: \(error)")
            // NUEVO: Usar sonido del sistema como respaldo
            AudioServicesPlaySystemSound(1005)
        }
    }
}

// SOLUCIÓN 3: FUNCIÓN PARA VERIFICAR LA PRESENCIA DEL ARCHIVO DE SONIDO

// Agregar esta función a la vista de cámara o a la clase que necesite verificar
func checkAlarmSoundFile() {
    print("Comprobando archivo de sonido 'alarm_sound.mp3':")
    
    if let soundURL = Bundle.main.url(forResource: "alarm_sound", withExtension: "mp3") {
        print("✅ ÉXITO: Archivo encontrado en \(soundURL)")
        
        // Verificar si el archivo se puede leer
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: soundURL.path)
            let fileSize = attributes[.size] as? UInt64 ?? 0
            print("   - Tamaño del archivo: \(fileSize) bytes")
            
            if fileSize == 0 {
                print("⚠️ ADVERTENCIA: El archivo existe pero está vacío")
            }
        } catch {
            print("⚠️ ADVERTENCIA: El archivo existe pero no se pudo leer: \(error)")
        }
    } else {
        print("❌ ERROR: Archivo 'alarm_sound.mp3' NO ENCONTRADO en el bundle")
        print("   Posibles soluciones:")
        print("   1. Verifica que el archivo esté incluido en el 'Copy Bundle Resources'")
        print("   2. Asegúrate de que el nombre del archivo sea exactamente 'alarm_sound.mp3'")
        print("   3. Intenta limpiar el proyecto (Clean Build Folder) y volver a construir")
    }
    
    // NUEVO: Como alternativa, buscar cualquier archivo de audio en el bundle
    print("\nBuscando archivos de audio alternativos en el bundle:")
    let fileTypes = ["mp3", "wav", "aac", "m4a"]
    var foundAnyAudioFile = false
    
    for fileType in fileTypes {
        if let urls = Bundle.main.urls(forResourcesWithExtension: fileType, subdirectory: nil), !urls.isEmpty {
            print("✅ Encontrados \(urls.count) archivos .\(fileType):")
            for url in urls {
                print("   - \(url.lastPathComponent)")
            }
            foundAnyAudioFile = true
        }
    }
    
    if !foundAnyAudioFile {
        print("❌ No se encontraron archivos de audio en el bundle")
    }
}

// SOLUCIÓN 4: MODIFICAR LA FUNCIÓN checkAndTriggerAlarm PARA TRABAJAR SIN WEATHERKIT

func checkAndTriggerAlarm(objectDetected: Bool, objectDistance: Double, locationManager: LocationManager, visibility: Double = 100.0) {
    // Si no hay datos de WeatherKit, usar un valor predeterminado para visibility
    let actualVisibility = visibility > 0 ? visibility : 100.0 // Valor por defecto (condiciones secas)
    
    // Obtener velocidad actual
    let speed = locationManager.speed
    
    print("\n--- Evaluando necesidad de alarma ---")
    print("Objeto detectado a: \(objectDistance) metros")
    print("Velocidad actual: \(speed) km/h")
    print("Visibilidad determinada: \(actualVisibility) metros")
    
    let alarmSystem = AlarmSystem(
        objectDetected: objectDetected,
        objectDistance: objectDistance,
        currentSpeed: speed,
        visibility: actualVisibility
    )
    
    if alarmSystem.shouldTriggerAlarm() {
        print("🚨 ALARMA ACTIVADA: Objeto a \(objectDistance) metros con velocidad \(speed) km/h")
        configureAudioSessionForPlayback()
        AlarmManager.shared.emitAlarmSound() // Emite el sonido de alarma
    } else {
        print("✓ Alarma no activada: Condiciones no cumplen criterios")
    }
    print("------------------------\n")
}
