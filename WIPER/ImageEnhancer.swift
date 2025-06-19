//
//  ImageEnhancer.swift
//  WIPER
//
//  Created by Andrea Lima Blanca on 11/11/24.
//

import CoreImage
import UIKit

/// Clase responsable de aplicar diversas mejoras y filtros a las imágenes.
/// Utiliza Core Image para el procesamiento de filtros.
class ImageEnhancer {
    /// Un contexto de Core Image para renderizar los resultados de los filtros.
    /// Se reutiliza para mejorar la eficiencia.
    let context = CIContext()

    /// Aplica una serie de filtros para mejorar la imagen, simulando un efecto CLAHE (Contrast Limited Adaptive Histogram Equalization).
    /// Esta función ajusta la vivacidad, brillo, contraste y las sombras/luces altas de la imagen.
    ///
    /// - Parameters:
    ///   - image: La `UIImage` original a procesar.
    ///   - vibrance: El nivel de ajuste de vivacidad. Valor por defecto: 1.0.
    ///   - brightness: El nivel de ajuste de brillo. Valor por defecto: 0.0.
    ///   - contrast: El nivel de ajuste de contraste. Valor por defecto: 1.2.
    ///   - highlightAmount: La cantidad de ajuste para las luces altas. Valor por defecto: 0.7.
    ///   - shadowAmount: La cantidad de ajuste para las sombras. Valor por defecto: 0.3.
    /// - Returns: Una `UIImage` opcional con los filtros aplicados, o `nil` si el procesamiento falla.
    func applyCLAHE(to image: UIImage, vibrance: Float = 1.0, brightness: Float = 0.0, contrast: Float = 1.2, highlightAmount: Float = 0.7, shadowAmount: Float = 0.3) -> UIImage? {
        // Convierte UIImage a CIImage para poder usarla con los filtros de Core Image.
        guard let ciImage = CIImage(image: image) else { return nil }

        // Aplicar filtro de Vivacidad (CIVibrance)
        // Aumenta la saturación de los colores menos saturados, sin sobresaturar los colores ya saturados.
        guard let vibranceFilter = CIFilter(name: "CIVibrance") else { return nil }
        vibranceFilter.setValue(ciImage, forKey: kCIInputImageKey) // Establece la imagen de entrada.
        vibranceFilter.setValue(vibrance, forKey: "inputAmount")   // Establece la intensidad del efecto.
        // Obtiene la imagen resultante del filtro de vivacidad.
        guard let vibranceOutput = vibranceFilter.outputImage else { return nil }

        // Aplicar filtro de Controles de Color (CIColorControls)
        // Ajusta el brillo y contraste de la imagen.
        guard let colorControlsFilter = CIFilter(name: "CIColorControls") else { return nil }
        colorControlsFilter.setValue(vibranceOutput, forKey: kCIInputImageKey) // Usa la salida del filtro anterior.
        colorControlsFilter.setValue(brightness, forKey: kCIInputBrightnessKey) // Ajusta el brillo.
        colorControlsFilter.setValue(contrast, forKey: kCIInputContrastKey)     // Ajusta el contraste.
        // Obtiene la imagen resultante del filtro de controles de color.
        guard let colorControlsOutput = colorControlsFilter.outputImage else { return nil }

        // Aplicar filtro de Ajuste de Sombras y Luces Altas (CIHighlightShadowAdjust)
        // Modifica las luces altas y las sombras de la imagen.
        guard let highlightShadowAdjustFilter = CIFilter(name: "CIHighlightShadowAdjust") else { return nil }
        highlightShadowAdjustFilter.setValue(colorControlsOutput, forKey: kCIInputImageKey) // Usa la salida del filtro anterior.
        highlightShadowAdjustFilter.setValue(highlightAmount, forKey: "inputHighlightAmount") // Ajusta la intensidad de las luces altas.
        highlightShadowAdjustFilter.setValue(shadowAmount, forKey: "inputShadowAmount")       // Ajusta la intensidad de las sombras.

        // Convierte la CIImage final de vuelta a UIImage.
        return outputImage(for: highlightShadowAdjustFilter)
    }

    /// Aplica un filtro de ecualización de histograma a la imagen para mejorar el contraste global.
    /// Se ajusta el contraste y luego se aplica una curva de tonos para redistribuir las intensidades.
    ///
    /// - Parameters:
    ///   - image: La `UIImage` original a procesar.
    ///   - contrast: El nivel de ajuste de contraste inicial. Valor por defecto: 1.2.
    /// - Returns: Una `UIImage` opcional con el filtro aplicado, o `nil` si el procesamiento falla.
    func applyHistogramEqualization(to image: UIImage, contrast: Float = 1.2) -> UIImage? {
        // Convierte UIImage a CIImage.
        guard let ciImage = CIImage(image: image) else { return nil }
        
        // 1. Aplicar filtro de Controles de Color (CIColorControls) para ajustar el contraste inicial.
        guard let colorControlsFilter = CIFilter(name: "CIColorControls") else { return nil }
        colorControlsFilter.setValue(ciImage, forKey: kCIInputImageKey)
        colorControlsFilter.setValue(contrast, forKey: kCIInputContrastKey)
        // Obtiene la imagen resultante del filtro de controles de color.
        guard let colorControlsOutput = colorControlsFilter.outputImage else { return nil }
        
        // 2. Aplicar filtro de Curva de Tonos (CIToneCurve)
        // Ajusta los tonos de la imagen usando puntos de control para definir la curva.
        // Esta curva específica intenta expandir el rango dinámico, similar a una ecualización.
        guard let toneCurveFilter = CIFilter(name: "CIToneCurve") else { return nil }
        toneCurveFilter.setValue(colorControlsOutput, forKey: kCIInputImageKey) // Usa la salida del filtro anterior.
        // Define los puntos de la curva de tonos. (x,y) donde x es la intensidad original y y es la nueva intensidad.
        toneCurveFilter.setValue(CIVector(x: 0.0, y: 0.0), forKey: "inputPoint0") // Negro permanece negro.
        toneCurveFilter.setValue(CIVector(x: 0.3, y: 0.4), forKey: "inputPoint1") // Sombras oscuras se aclaran ligeramente.
        toneCurveFilter.setValue(CIVector(x: 0.5, y: 0.5), forKey: "inputPoint2") // Tonos medios permanecen igual.
        toneCurveFilter.setValue(CIVector(x: 0.7, y: 0.6), forKey: "inputPoint3") // Luces claras se oscurecen ligeramente (puede ser un error y debería ser > 0.7).
        toneCurveFilter.setValue(CIVector(x: 1.0, y: 1.0), forKey: "inputPoint4") // Blanco permanece blanco.

        // Convierte la CIImage final de vuelta a UIImage.
        return outputImage(for: toneCurveFilter)
    }

    /// Aplica un filtro para reducir el efecto de neblina (dehaze) en una imagen.
    /// Ajusta el contraste, saturación, brillo, exposición y reduce el ruido.
    ///
    /// - Parameters:
    ///   - image: La `UIImage` original a procesar.
    ///   - brightness: Nivel de brillo. Valor por defecto: 0.1.
    ///   - contrast: Nivel de contraste. Valor por defecto: 1.2.
    ///   - saturation: Nivel de saturación. Valor por defecto: 1.0.
    ///   - exposure: Nivel de exposición. Valor por defecto: 0.5.
    ///   - noiseReduction: Nivel de reducción de ruido. Valor por defecto: 0.02.
    /// - Returns: Una `UIImage` opcional con el filtro aplicado, o `nil` si el procesamiento falla.
    func applyDehaze(to image: UIImage, brightness: Float = 0.1, contrast: Float = 1.2, saturation: Float = 1.0, exposure: Float = 0.5, noiseReduction: Float = 0.02) -> UIImage? {
        // Convierte UIImage a CIImage.
        guard let ciImage = CIImage(image: image) else { return nil }

        // 1. Aplicar filtro de Controles de Color (CIColorControls)
        // Ajusta contraste, saturación y brillo.
        guard let colorControlsFilter = CIFilter(name: "CIColorControls") else { return nil }
        colorControlsFilter.setValue(ciImage, forKey: kCIInputImageKey)
        colorControlsFilter.setValue(contrast, forKey: kCIInputContrastKey)
        colorControlsFilter.setValue(saturation, forKey: kCIInputSaturationKey)
        colorControlsFilter.setValue(brightness, forKey: kCIInputBrightnessKey)
        // Obtiene la imagen resultante.
        guard let colorControlsOutput = colorControlsFilter.outputImage else { return nil }

        // 2. Aplicar filtro de Ajuste de Exposición (CIExposureAdjust)
        guard let exposureFilter = CIFilter(name: "CIExposureAdjust") else { return nil }
        exposureFilter.setValue(colorControlsOutput, forKey: kCIInputImageKey) // Usa la salida del filtro anterior.
        exposureFilter.setValue(exposure, forKey: kCIInputEVKey) // Ajusta la exposición.
        // Obtiene la imagen resultante.
        guard let exposureOutput = exposureFilter.outputImage else { return nil }

        // 3. Aplicar filtro de Reducción de Ruido (CINoiseReduction)
        guard let noiseReductionFilter = CIFilter(name: "CINoiseReduction") else { return nil }
        noiseReductionFilter.setValue(exposureOutput, forKey: kCIInputImageKey) // Usa la salida del filtro anterior.
        noiseReductionFilter.setValue(noiseReduction, forKey: "inputNoiseLevel") // Establece el nivel de reducción de ruido.
        // Obtiene la imagen resultante.
        guard let noiseReductionOutput = noiseReductionFilter.outputImage else { return nil }

        // 4. Aplicar filtro de Curva de Tonos Lineal a sRGB (CILinearToSRGBToneCurve)
        // Convierte la imagen de un espacio de color lineal a sRGB, lo que puede mejorar la apariencia visual en pantallas estándar.
        guard let toneCurveFilter = CIFilter(name: "CILinearToSRGBToneCurve") else { return nil }
        toneCurveFilter.setValue(noiseReductionOutput, forKey: kCIInputImageKey) // Usa la salida del filtro anterior.

        // Convierte la CIImage final de vuelta a UIImage.
        return outputImage(for: toneCurveFilter)
    }

    /// Aplica un filtro para simular la eliminación de lluvia de una imagen.
    /// Principalmente utiliza reducción de ruido y luego aplica un filtro de nitidez.
    ///
    /// - Parameters:
    ///   - image: La `UIImage` original a procesar.
    ///   - noiseReduction: Nivel de reducción de ruido. Valor por defecto: 0.02.
    ///   - sharpen: Nivel de nitidez. Valor por defecto: 0.4.
    /// - Returns: Una `UIImage` opcional con el filtro aplicado, o `nil` si el procesamiento falla.
    func applyRainRemoval(to image: UIImage, noiseReduction: Float = 0.02, sharpen: Float = 0.4) -> UIImage? {
        // Convierte UIImage a CIImage.
        guard let ciImage = CIImage(image: image) else { return nil }

        // 1. Aplicar filtro de Reducción de Ruido (CINoiseReduction)
        // Este filtro también tiene un parámetro de nitidez que se ajusta aquí.
        guard let noiseReductionFilter = CIFilter(name: "CINoiseReduction") else { return nil }
        noiseReductionFilter.setValue(ciImage, forKey: kCIInputImageKey)
        noiseReductionFilter.setValue(noiseReduction, forKey: "inputNoiseLevel") // Nivel de reducción de ruido.
        noiseReductionFilter.setValue(0.40, forKey: "inputSharpness")         // Nivel de nitidez dentro del filtro de reducción de ruido.
        // Obtiene la imagen resultante.
        guard let noiseReductionOutput = noiseReductionFilter.outputImage else { return nil }

        // 2. Aplicar filtro de Nitidez de Luminancia (CISharpenLuminance)
        // Aumenta la nitidez basándose en la luminancia de la imagen.
        guard let sharpenFilter = CIFilter(name: "CISharpenLuminance") else { return nil }
        sharpenFilter.setValue(noiseReductionOutput, forKey: kCIInputImageKey) // Usa la salida del filtro anterior.
        sharpenFilter.setValue(sharpen, forKey: "inputSharpness")             // Nivel de nitidez.

        // Convierte la CIImage final de vuelta a UIImage.
        return outputImage(for: sharpenFilter)
    }

    /// Aplica filtros para mejorar la visibilidad en imágenes nocturnas.
    /// Ajusta la exposición, sombras, reduce ruido y aplica nitidez.
    ///
    /// - Parameters:
    ///   - image: La `UIImage` original a procesar.
    ///   - exposure: Nivel de exposición. Valor por defecto: 0.8.
    ///   - shadowAmount: Nivel de ajuste de sombras. Valor por defecto: 0.8.
    ///   - noiseReduction: Nivel de reducción de ruido. Valor por defecto: 0.1.
    ///   - sharpen: Nivel de nitidez. Valor por defecto: 0.5.
    /// - Returns: Una `UIImage` opcional con el filtro aplicado, o `nil` si el procesamiento falla.
    func applyNightEnhancement(to image: UIImage, exposure: Float = 0.8, shadowAmount: Float = 0.8, noiseReduction: Float = 0.1, sharpen: Float = 0.5) -> UIImage? {
        // Convierte UIImage a CIImage.
        guard let ciImage = CIImage(image: image) else { return nil }

        // 1. Aplicar filtro de Ajuste de Exposición (CIExposureAdjust)
        guard let exposureFilter = CIFilter(name: "CIExposureAdjust") else { return nil }
        exposureFilter.setValue(ciImage, forKey: kCIInputImageKey)
        exposureFilter.setValue(exposure, forKey: kCIInputEVKey) // Ajusta la exposición.
        // Obtiene la imagen resultante.
        guard let exposureOutput = exposureFilter.outputImage else { return nil }

        // 2. Aplicar filtro de Ajuste de Sombras y Luces Altas (CIHighlightShadowAdjust)
        // Se enfoca en levantar las sombras.
        guard let highlightShadowAdjustFilter = CIFilter(name: "CIHighlightShadowAdjust") else { return nil }
        highlightShadowAdjustFilter.setValue(exposureOutput, forKey: kCIInputImageKey) // Usa la salida del filtro anterior.
        highlightShadowAdjustFilter.setValue(shadowAmount, forKey: "inputShadowAmount") // Ajusta la intensidad de las sombras.
        // Obtiene la imagen resultante.
        guard let highlightShadowOutput = highlightShadowAdjustFilter.outputImage else { return nil }

        // 3. Aplicar filtro de Reducción de Ruido (CINoiseReduction)
        guard let noiseReductionFilter = CIFilter(name: "CINoiseReduction") else { return nil }
        noiseReductionFilter.setValue(highlightShadowOutput, forKey: kCIInputImageKey) // Usa la salida del filtro anterior.
        noiseReductionFilter.setValue(noiseReduction, forKey: "inputNoiseLevel")     // Nivel de reducción de ruido.
        // Obtiene la imagen resultante.
        guard let noiseReductionOutput = noiseReductionFilter.outputImage else { return nil }

        // 4. Aplicar filtro de Nitidez de Luminancia (CISharpenLuminance)
        guard let sharpenFilter = CIFilter(name: "CISharpenLuminance") else { return nil }
        sharpenFilter.setValue(noiseReductionOutput, forKey: kCIInputImageKey) // Usa la salida del filtro anterior.
        sharpenFilter.setValue(sharpen, forKey: "inputSharpness")             // Nivel de nitidez.

        // Convierte la CIImage final de vuelta a UIImage.
        return outputImage(for: sharpenFilter)
    }

    /// Función auxiliar privada para convertir la `CIImage` resultante de un filtro a `UIImage`.
    ///
    /// - Parameter filter: El `CIFilter` que contiene la `outputImage` a convertir.
    /// - Returns: Una `UIImage` opcional, o `nil` si la conversión o la obtención de la imagen fallan.
    private func outputImage(for filter: CIFilter?) -> UIImage? {
        // Asegura que el filtro y su imagen de salida existan.
        guard let outputCIImage = filter?.outputImage,
              // Crea una CGImage desde la CIImage usando el contexto. La extensión define el área a renderizar.
              let cgImage = context.createCGImage(outputCIImage, from: outputCIImage.extent) else {
            return nil // Retorna nil si alguno de los pasos falla.
        }
        // Crea y retorna una UIImage desde la CGImage.
        return UIImage(cgImage: cgImage)
    }
}
