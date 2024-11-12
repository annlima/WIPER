//
//  ImageEnhancer.swift
//  WIPER
//
//  Created by Andrea Lima Blanca on 11/11/24.
//

import CoreImage
import UIKit

class ImageEnhancer {
    let context = CIContext()

    func applyCLAHE(to image: UIImage, vibrance: Float = 1.0, brightness: Float = 0.0, contrast: Float = 1.2, highlightAmount: Float = 0.7, shadowAmount: Float = 0.3) -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return nil }

        guard let vibranceFilter = CIFilter(name: "CIVibrance") else { return nil }
        vibranceFilter.setValue(ciImage, forKey: kCIInputImageKey)
        vibranceFilter.setValue(vibrance, forKey: "inputAmount")
        guard let vibranceOutput = vibranceFilter.outputImage else { return nil }

        guard let colorControlsFilter = CIFilter(name: "CIColorControls") else { return nil }
        colorControlsFilter.setValue(vibranceOutput, forKey: kCIInputImageKey)
        colorControlsFilter.setValue(brightness, forKey: kCIInputBrightnessKey)
        colorControlsFilter.setValue(contrast, forKey: kCIInputContrastKey)
        guard let colorControlsOutput = colorControlsFilter.outputImage else { return nil }

        guard let highlightShadowAdjustFilter = CIFilter(name: "CIHighlightShadowAdjust") else { return nil }
        highlightShadowAdjustFilter.setValue(colorControlsOutput, forKey: kCIInputImageKey)
        highlightShadowAdjustFilter.setValue(highlightAmount, forKey: "inputHighlightAmount")
        highlightShadowAdjustFilter.setValue(shadowAmount, forKey: "inputShadowAmount")

        return outputImage(for: highlightShadowAdjustFilter)
    }

    func applyHistogramEqualization(to image: UIImage, contrast: Float = 1.2) -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return nil }
        
        guard let colorControlsFilter = CIFilter(name: "CIColorControls") else { return nil }
        colorControlsFilter.setValue(ciImage, forKey: kCIInputImageKey)
        colorControlsFilter.setValue(contrast, forKey: kCIInputContrastKey)
        guard let colorControlsOutput = colorControlsFilter.outputImage else { return nil }
        
        guard let toneCurveFilter = CIFilter(name: "CIToneCurve") else { return nil }
        toneCurveFilter.setValue(colorControlsOutput, forKey: kCIInputImageKey)
        toneCurveFilter.setValue(CIVector(x: 0.0, y: 0.0), forKey: "inputPoint0")
        toneCurveFilter.setValue(CIVector(x: 0.3, y: 0.4), forKey: "inputPoint1")
        toneCurveFilter.setValue(CIVector(x: 0.5, y: 0.5), forKey: "inputPoint2")
        toneCurveFilter.setValue(CIVector(x: 0.7, y: 0.6), forKey: "inputPoint3")
        toneCurveFilter.setValue(CIVector(x: 1.0, y: 1.0), forKey: "inputPoint4")

        return outputImage(for: toneCurveFilter)
    }
    func applyDehaze(to image: UIImage, brightness: Float = 0.1, contrast: Float = 1.2, saturation: Float = 1.0, exposure: Float = 0.5, noiseReduction: Float = 0.02) -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return nil }

        // Adjust Color Controls for brightness, contrast, and saturation
        guard let colorControlsFilter = CIFilter(name: "CIColorControls") else { return nil }
        colorControlsFilter.setValue(ciImage, forKey: kCIInputImageKey)
        colorControlsFilter.setValue(contrast, forKey: kCIInputContrastKey)
        colorControlsFilter.setValue(saturation, forKey: kCIInputSaturationKey)
        colorControlsFilter.setValue(brightness, forKey: kCIInputBrightnessKey)
        guard let colorControlsOutput = colorControlsFilter.outputImage else { return nil }

        // Adjust Exposure
        guard let exposureFilter = CIFilter(name: "CIExposureAdjust") else { return nil }
        exposureFilter.setValue(colorControlsOutput, forKey: kCIInputImageKey)
        exposureFilter.setValue(exposure, forKey: kCIInputEVKey)
        guard let exposureOutput = exposureFilter.outputImage else { return nil }

        // Apply Noise Reduction
        guard let noiseReductionFilter = CIFilter(name: "CINoiseReduction") else { return nil }
        noiseReductionFilter.setValue(exposureOutput, forKey: kCIInputImageKey)
        noiseReductionFilter.setValue(noiseReduction, forKey: "inputNoiseLevel")
        guard let noiseReductionOutput = noiseReductionFilter.outputImage else { return nil }

        // Finalize with tone curve adjustment for better light distribution
        guard let toneCurveFilter = CIFilter(name: "CILinearToSRGBToneCurve") else { return nil }
        toneCurveFilter.setValue(noiseReductionOutput, forKey: kCIInputImageKey)

        return outputImage(for: toneCurveFilter)
    

    
    }

    func applyRainRemoval(to image: UIImage, noiseReduction: Float = 0.02, sharpen: Float = 0.4) -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return nil }

        guard let noiseReductionFilter = CIFilter(name: "CINoiseReduction") else { return nil }
        noiseReductionFilter.setValue(ciImage, forKey: kCIInputImageKey)
        noiseReductionFilter.setValue(noiseReduction, forKey: "inputNoiseLevel")
        noiseReductionFilter.setValue(0.40, forKey: "inputSharpness")
        guard let noiseReductionOutput = noiseReductionFilter.outputImage else { return nil }

        guard let sharpenFilter = CIFilter(name: "CISharpenLuminance") else { return nil }
        sharpenFilter.setValue(noiseReductionOutput, forKey: kCIInputImageKey)
        sharpenFilter.setValue(sharpen, forKey: "inputSharpness")

        return outputImage(for: sharpenFilter)
    }

    func applyNightEnhancement(to image: UIImage, exposure: Float = 0.8, shadowAmount: Float = 0.8, noiseReduction: Float = 0.1, sharpen: Float = 0.5) -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return nil }

        guard let exposureFilter = CIFilter(name: "CIExposureAdjust") else { return nil }
        exposureFilter.setValue(ciImage, forKey: kCIInputImageKey)
        exposureFilter.setValue(exposure, forKey: kCIInputEVKey)
        guard let exposureOutput = exposureFilter.outputImage else { return nil }

        guard let highlightShadowAdjustFilter = CIFilter(name: "CIHighlightShadowAdjust") else { return nil }
        highlightShadowAdjustFilter.setValue(exposureOutput, forKey: kCIInputImageKey)
        highlightShadowAdjustFilter.setValue(shadowAmount, forKey: "inputShadowAmount")
        guard let highlightShadowOutput = highlightShadowAdjustFilter.outputImage else { return nil }

        guard let noiseReductionFilter = CIFilter(name: "CINoiseReduction") else { return nil }
        noiseReductionFilter.setValue(highlightShadowOutput, forKey: kCIInputImageKey)
        noiseReductionFilter.setValue(noiseReduction, forKey: "inputNoiseLevel")
        guard let noiseReductionOutput = noiseReductionFilter.outputImage else { return nil }

        guard let sharpenFilter = CIFilter(name: "CISharpenLuminance") else { return nil }
        sharpenFilter.setValue(noiseReductionOutput, forKey: kCIInputImageKey)
        sharpenFilter.setValue(sharpen, forKey: "inputSharpness")

        return outputImage(for: sharpenFilter)
    }

    private func outputImage(for filter: CIFilter?) -> UIImage? {
        guard let outputCIImage = filter?.outputImage,
              let cgImage = context.createCGImage(outputCIImage, from: outputCIImage.extent) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }
}

