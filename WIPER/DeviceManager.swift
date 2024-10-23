import UIKit

class DeviceManager {
    static let shared = DeviceManager()
    
    private init() {
        detectDevice()
    }
    
    private(set) var deviceModel: String = ""
    private(set) var systemVersion: String = ""
    private(set) var screenSize: String = ""

    private func detectDevice() {
        let device = UIDevice.current
        systemVersion = device.systemVersion
        if let modelCode = getModelCode() {
            deviceModel = modelCode
        } else {
            deviceModel = "Desconocido"
        }
        
        let screen = UIScreen.main.bounds
        screenSize = "\(Int(screen.width)) x \(Int(screen.height)) puntos"
        
        print("Modelo del dispositivo: \(deviceModel)")
        print("Versión de iOS: \(systemVersion)")
        print("Tamaño de la pantalla: \(screenSize)")
    }

    private func getModelCode() -> String? {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return mapToDevice(identifier: identifier)
    }

    private func mapToDevice(identifier: String) -> String {
        switch identifier {
        // iPhone XR
        case "iPhone11,8": return "iPhone XR"
        // iPhone XS, XS Max
        case "iPhone11,2": return "iPhone XS"
        case "iPhone11,6", "iPhone11,4": return "iPhone XS Max"
        // iPhone 11, 11 Pro, 11 Pro Max
        case "iPhone12,1": return "iPhone 11"
        case "iPhone12,3": return "iPhone 11 Pro"
        case "iPhone12,5": return "iPhone 11 Pro Max"
        // iPhone SE (2da generación)
        case "iPhone12,8": return "iPhone SE (2da generación)"
        // iPhone 12 mini, 12, 12 Pro, 12 Pro Max
        case "iPhone13,1": return "iPhone 12 mini"
        case "iPhone13,2": return "iPhone 12"
        case "iPhone13,3": return "iPhone 12 Pro"
        case "iPhone13,4": return "iPhone 12 Pro Max"
        // iPhone 13 mini, 13, 13 Pro, 13 Pro Max
        case "iPhone14,4": return "iPhone 13 mini"
        case "iPhone14,5": return "iPhone 13"
        case "iPhone14,2": return "iPhone 13 Pro"
        case "iPhone14,3": return "iPhone 13 Pro Max"
        // iPhone SE (3ra generación)
        case "iPhone14,6": return "iPhone SE (3ra generación)"
        // iPhone 14, 14 Plus, 14 Pro, 14 Pro Max
        case "iPhone14,7": return "iPhone 14"
        case "iPhone14,8": return "iPhone 14 Plus"
        case "iPhone15,2": return "iPhone 14 Pro"
        case "iPhone15,3": return "iPhone 14 Pro Max"
        // iPhone 15, 15 Plus, 15 Pro, 15 Pro Max
        case "iPhone15,4": return "iPhone 15"
        case "iPhone15,5": return "iPhone 15 Plus"
        case "iPhone16,1": return "iPhone 15 Pro"
        case "iPhone16,2": return "iPhone 15 Pro Max"
        // iPhone 16 (Provisional)
        case "iPhone16,3": return "iPhone 16"
        case "iPhone16,4": return "iPhone 16 Plus"
        case "iPhone16,5": return "iPhone 16 Pro"
        case "iPhone16,6": return "iPhone 16 Pro Max"
        default: return identifier
        }
    }
}

// Uso
let deviceModel = DeviceManager.shared.deviceModel
