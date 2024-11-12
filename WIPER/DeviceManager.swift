import UIKit
import AVFoundation
import SwiftUI
import CoreLocation
import Vision

class DeviceManager {
    static let shared = DeviceManager()
    
    private init() {
        detectDevice()
    }
    
    private(set) var deviceModel: String = ""
    private(set) var systemVersion: String = ""
    private(set) var screenSize: String = ""
    private(set) var focalLength: CGFloat = 0.0

    private func detectDevice() {
        let device = UIDevice.current
        systemVersion = device.systemVersion
        if let modelCode = getModelCode() {
            deviceModel = modelCode
            focalLength = getFocalLength(for: modelCode)
            print("Focal length for model \(modelCode): \(focalLength)")
        } else {
            deviceModel = "Desconocido"
            focalLength = 0.0
        }
        
        let screen = UIScreen.main.bounds
        screenSize = "\(Int(screen.width)) x \(Int(screen.height)) puntos"
        
        print("Modelo del dispositivo: \(deviceModel)")
        print("Versión de iOS: \(systemVersion)")
        print("Tamaño de la pantalla: \(screenSize)")
        print("Longitud focal: \(focalLength) mm")
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
    
    private func getFocalLength(for modelCode: String) -> CGFloat {
        let focalLengths: [String: CGFloat] = [
            // iPhone XR and XS series
            "iPhone11,8": 4.25,   // iPhone XR
            "iPhone11,2": 4.25,   // iPhone XS
            "iPhone11,4": 4.25,   // iPhone XS Max
            "iPhone11,6": 4.25,   // iPhone XS Max (alternative code)
            // iPhone 11 series
            "iPhone12,1": 4.25,   // iPhone 11
            "iPhone12,3": 4.25,   // iPhone 11 Pro (main wide camera)
            "iPhone12,5": 4.25,   // iPhone 11 Pro Max (main wide camera)
            // iPhone 12 series
            "iPhone13,1": 4.25,   // iPhone 12 mini
            "iPhone13,2": 4.25,   // iPhone 12
            "iPhone13,3": 4.25,   // iPhone 12 Pro (main wide camera)
            "iPhone13,4": 4.25,   // iPhone 12 Pro Max (main wide camera)
            // iPhone 13 series
            "iPhone14,4": 4.25,   // iPhone 13 mini
            "iPhone14,5": 4.25,   // iPhone 13
            "iPhone14,2": 4.25,   // iPhone 13 Pro (main wide camera)
            "iPhone14,3": 4.25,   // iPhone 13 Pro Max (main wide camera)
            // iPhone 14 series
            "iPhone14,7": 4.25,   // iPhone 14
            "iPhone14,8": 4.25,   // iPhone 14 Plus
            "iPhone15,2": 3.5,    // iPhone 14 Pro (main wide camera)
            "iPhone15,3": 3.5,    // iPhone 14 Pro Max (main wide camera)
            // iPhone 15 series (estimates based on iPhone 14 series)
            "iPhone15,4": 4.25,   // iPhone 15
            "iPhone15,5": 4.25,   // iPhone 15 Plus
            "iPhone16,1": 3.5,    // iPhone 15 Pro (main wide camera)
            "iPhone16,2": 3.5,    // iPhone 15 Pro Max (main wide camera)
            // iPhone 16 series (estimates based on iPhone 15 series)
            "iPhone16,3": 4.25,   // iPhone 16
            "iPhone16,4": 4.25,   // iPhone 16 Plus
            "iPhone16,5": 3.5,    // iPhone 16 Pro
            "iPhone16,6": 3.5     // iPhone 16 Pro Max
        ]

        return focalLengths[modelCode] ?? 4.25
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
