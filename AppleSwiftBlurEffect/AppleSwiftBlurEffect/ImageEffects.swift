//
//  ImageEffects.swift
//  AppleSwiftBlurEffect
//
//  Created by Phoenix on 2016/12/19.
//  Copyright © 2016年 Wolkamo. All rights reserved.
//

import UIKit
import Accelerate

public extension UIImage {
    
    public func applyLightEffect() -> UIImage? {
        return applyBlurWithRadius(30, tintColor: UIColor(white: 1.0, alpha: 0.3), saturationDeltaFactor: 1.8)
    }
    
    public func applyExtraLightEffect() -> UIImage? {
        return applyBlurWithRadius(20, tintColor: UIColor(white: 0.97, alpha: 0.82), saturationDeltaFactor: 1.8)
    }
    
    public func applyDarkEffect() -> UIImage? {
        return applyBlurWithRadius(20, tintColor: UIColor(white: 0.11, alpha: 0.73), saturationDeltaFactor: 1.8)
    }
    
    public func applyTintEffectWithColor(_ tintColor: UIColor) -> UIImage? {
        let effectColorAlpha: CGFloat = 0.6
        var effectColor = tintColor
        
        let componentCount = tintColor.cgColor.numberOfComponents
        
        if componentCount == 2 {
            var b: CGFloat = 0
            if tintColor.getWhite(&b, alpha: nil) {
                effectColor = UIColor(white: b, alpha: effectColorAlpha)
            }
        } else {
            var red: CGFloat = 0
            var green: CGFloat = 0
            var blue: CGFloat = 0
            
            if tintColor.getRed(&red, green: &green, blue: &blue, alpha: nil) {
                effectColor = UIColor(red: red, green: green, blue: blue, alpha: effectColorAlpha)
            }
        }
        
        return applyBlurWithRadius(10, tintColor: effectColor, saturationDeltaFactor: -1.0, maskImage: nil)
    }
    
    public func applyBlurWithRadius(_ blurRadius: CGFloat, tintColor: UIColor?, saturationDeltaFactor: CGFloat, maskImage: UIImage? = nil) -> UIImage? {
        
        if (size.width < 1 || size.height < 1) {
            print("*** error: invalid size: \(size.width) x \(size.height). Both dimensions must be >= 1: \(self)")
            return nil
        }
        guard let cgImage = self.cgImage else {
            print("*** error: image must be backed by a CGImage: \(self)")
            return nil
        }
        if maskImage != nil && maskImage!.cgImage == nil {
            print("*** error: maskImage must be backed by a CGImage: \(maskImage)")
            return nil
        }
        
        let screenScale = UIScreen.main.scale
        let imageRect = CGRect(origin: CGPoint.zero, size: size)
        var effectImage = self
        
        let hasBlur = blurRadius > CGFloat(FLT_EPSILON)
        let hasSaturationChange = fabs(saturationDeltaFactor - 1.0) > CGFloat(FLT_EPSILON)
        
        if hasBlur || hasSaturationChange {
            func createEffectBuffer(_ context: CGContext) -> vImage_Buffer {
                let data = context.data
                let width = vImagePixelCount(context.width)
                let height = vImagePixelCount(context.height)
                let rowBytes = context.bytesPerRow
                
                return vImage_Buffer(data: data, height: height, width: width, rowBytes: rowBytes)
            }
            
            UIGraphicsBeginImageContextWithOptions(size, false, screenScale)
            guard let effectInContext = UIGraphicsGetCurrentContext() else { return  nil }
            
            effectInContext.scaleBy(x: 1.0, y: -1.0)
            effectInContext.translateBy(x: 0, y: -size.height)
            effectInContext.draw(cgImage, in: imageRect)
            
            var effectInBuffer = createEffectBuffer(effectInContext)
            
            
            UIGraphicsBeginImageContextWithOptions(size, false, screenScale)
            
            guard let effectOutContext = UIGraphicsGetCurrentContext() else { return  nil }
            var effectOutBuffer = createEffectBuffer(effectOutContext)
            
            
            if hasBlur {
                let inputRadius = blurRadius * screenScale
                let d = floor(inputRadius * 3.0 * CGFloat(sqrt(2 * M_PI) / 4 + 0.5))
                var radius = UInt32(d)
                if radius % 2 != 1 {
                    radius += 1
                }
                
                let imageEdgeExtendFlags = vImage_Flags(kvImageEdgeExtend)
                
                vImageBoxConvolve_ARGB8888(&effectInBuffer, &effectOutBuffer, nil, 0, 0, radius, radius, nil, imageEdgeExtendFlags)
                vImageBoxConvolve_ARGB8888(&effectOutBuffer, &effectInBuffer, nil, 0, 0, radius, radius, nil, imageEdgeExtendFlags)
                vImageBoxConvolve_ARGB8888(&effectInBuffer, &effectOutBuffer, nil, 0, 0, radius, radius, nil, imageEdgeExtendFlags)
            }
            
            var effectImageBuffersAreSwapped = false
            
            if hasSaturationChange {
                let s: CGFloat = saturationDeltaFactor
                let floatingPointSaturationMatrix: [CGFloat] = [
                    0.0722 + 0.9278 * s,  0.0722 - 0.0722 * s,  0.0722 - 0.0722 * s,  0,
                    0.7152 - 0.7152 * s,  0.7152 + 0.2848 * s,  0.7152 - 0.7152 * s,  0,
                    0.2126 - 0.2126 * s,  0.2126 - 0.2126 * s,  0.2126 + 0.7873 * s,  0,
                    0,                    0,                    0,                    1
                ]
                
                let divisor: CGFloat = 256
                let matrixSize = floatingPointSaturationMatrix.count
                var saturationMatrix = [Int16](repeating: 0, count: matrixSize)
                
                for i: Int in 0 ..< matrixSize {
                    saturationMatrix[i] = Int16(round(floatingPointSaturationMatrix[i] * divisor))
                }
                
                if hasBlur {
                    vImageMatrixMultiply_ARGB8888(&effectOutBuffer, &effectInBuffer, saturationMatrix, Int32(divisor), nil, nil, vImage_Flags(kvImageNoFlags))
                    effectImageBuffersAreSwapped = true
                } else {
                    vImageMatrixMultiply_ARGB8888(&effectInBuffer, &effectOutBuffer, saturationMatrix, Int32(divisor), nil, nil, vImage_Flags(kvImageNoFlags))
                }
            }
            
            if !effectImageBuffersAreSwapped {
                effectImage = UIGraphicsGetImageFromCurrentImageContext()!
            }
            
            UIGraphicsEndImageContext()
            
            if effectImageBuffersAreSwapped {
                effectImage = UIGraphicsGetImageFromCurrentImageContext()!
            }
            
            UIGraphicsEndImageContext()
        }
        
        UIGraphicsBeginImageContextWithOptions(size, false, screenScale)
        
        guard let outputContext = UIGraphicsGetCurrentContext() else { return nil }
        
        outputContext.scaleBy(x: 1.0, y: -1.0)
        outputContext.translateBy(x: 0, y: -size.height)
        
        outputContext.draw(cgImage, in: imageRect)
        
        if hasBlur {
            outputContext.saveGState()
            if let maskCGImage = maskImage?.cgImage {
                outputContext.clip(to: imageRect, mask: maskCGImage);
            }
            outputContext.draw(effectImage.cgImage!, in: imageRect)
            outputContext.restoreGState()
        }
        
        if let color = tintColor {
            outputContext.saveGState()
            outputContext.setFillColor(color.cgColor)
            outputContext.fill(imageRect)
            outputContext.restoreGState()
        }
        
        let outputImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return outputImage
    }

    
    public func rotateByDegress(_ degrees: CGFloat) -> UIImage {
        let rotatedViewBox = UIView.init(frame: CGRect.init(x: 0, y: 0, width: self.size.width, height: self.size.height))
        let t = CGAffineTransform.init(rotationAngle: degrees * CGFloat(M_PI) / 180.0)
        rotatedViewBox.transform = t
        let rotatedSize = rotatedViewBox.frame.size
        
        UIGraphicsBeginImageContext(rotatedSize)
        let bitmap = UIGraphicsGetCurrentContext()
        bitmap!.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
        bitmap!.rotate(by: degrees * CGFloat(M_PI) / 180.0)
        bitmap!.scaleBy(x: 1.0, y: -1.0)
        bitmap!.draw(self.cgImage!, in: CGRect.init(x: -self.size.width / 2, y: -self.size.height / 2, width: self.size.width, height: self.size.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
}


class ImageEffects {
    class public func imagePixelFromColor(_ color: UIColor) -> UIImage? {
        return imageFromColor(color, size: CGSize.init(width: 1.0, height: 1.0))!
    }
    
    class public func imageFromColor(_ color: UIColor, size: CGSize) -> UIImage? {
        let rect = CGRect.init(x: 0.0, y: 0.0, width: size.width, height: size.height)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()!
        context.setFillColor(color.cgColor)
        context.fill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
        
    }
}

