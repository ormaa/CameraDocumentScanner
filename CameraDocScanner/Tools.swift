//
//  Tools.swift
//  CameraDocumentScanner
//
//  Created by Olivier Robin on 16/11/2016.
//  Copyright © 2016 olivier. All rights reserved.
//

import Foundation
import UIKit

public class Tools: UIViewController {
    
    var uiViewController: UIViewController?
    
    // Save a picture to photo library
    // add in the info.plist : Privacy - Photo Library Usage Description + a description of the request displayed
    //
    public func savePhotoToLibrary(image: UIImage, uiViewController: UIViewController) {
        self.uiViewController = uiViewController
        // Save the transformed image to library
        //UIImageWriteToSavedPhotosAlbum(smallImage.image!, nil, nil, nil)
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
        
    }
    
    // Image written to photo library
    //
    public func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            // we got back an error!
            let ac = UIAlertController(title: "Save error", message: error.localizedDescription, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            uiViewController?.present(ac, animated: true)
        } else {
            let ac = UIAlertController(title: "Saved!", message: "Your document image has been saved to your photos library.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            uiViewController?.present(ac, animated: true)
        }
    }
    
    
    
    
    // Return a string containing the orientation of a UIImage
    //
    public static func getOrientation(o: UIImageOrientation) -> String {
        
        switch  o {
        case .up: // default orientation
            return "up"
        case .down: // 180 deg rotation
            return "down"
            
        case .left: // 90 deg CCW
            return "left"
            
        case .right: // 90 deg CW
            return "right"
            
        case .upMirrored: // as above but image mirrored along other axis. horizontal flip
            return "upMirrored"
            
        case .downMirrored: // horizontal flip
            return "downMirrored"
            
        case .leftMirrored: // vertical flip
            return "leftMirrored"
            
        case .rightMirrored: // vertical flip
            return "rightMirrored"
        }
        
    }
    
    
    
    
    
    
    
    // get an CGImage, return the same image, woth orientation = up, forced.
    //
    func createUIImageUp(imageRef: CGImage?) -> CGImage?
    {
        var orientedImage: CGImage?
        
        if let imageRef = imageRef {
            
            let originalWidth = imageRef.width
            let originalHeight = imageRef.height
            let bitsPerComponent = imageRef.bitsPerComponent
            let bytesPerRow = originalHeight * 4 // imageRef.bytesPerRow
            let colorSpace = imageRef.colorSpace
            let bitmapInfo = imageRef.bitmapInfo
            
            let radians = -1.5708 // = -90° //degreesToRotate(degreesToRotate)
            
            // Swap width/height
            let width = originalHeight
            let height = originalWidth
            
            print("size: " + String(describing: originalWidth) + " -- " + String(describing: originalHeight))
            print ("bit per component: " + String(describing: bitsPerComponent))
            print ("bit per row: " + String(describing: bytesPerRow))
            
            // bitmap = CGBitmapContextCreate(NULL, targetWidth, targetHeight, CGImageGetBitsPerComponent(imageRef), 0, colorSpaceInfo, bitmapInfo);
            
            let contextRef = CGContext(data: nil, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace!, bitmapInfo: bitmapInfo.rawValue)
            contextRef!.translateBy(x: CGFloat(width) / 2.0, y: CGFloat(height) / 2.0)
            
            contextRef!.rotate(by: CGFloat(radians))
            // swap
            contextRef!.translateBy(x: -CGFloat(height) / 2.0, y: -CGFloat(width) / 2.0)
            
            // redraw the img
            contextRef?.draw(imageRef, in: CGRect(x: 0, y: 0, width: CGFloat(originalWidth), height: CGFloat(originalHeight)))
            orientedImage = contextRef!.makeImage()
            
            print("cgImage size: " + String(describing: orientedImage?.width) + " --- " +  String(describing: orientedImage?.height) )
            
        }
        
        return orientedImage
    }
    
    // get an CGImage, return the same image, woth orientation = up, forced.
    //
    func createUIImageDown(imageRef: CGImage?) -> CGImage?
    {
        var orientedImage: CGImage?
        
        if let imageRef = imageRef {
            
            let originalWidth = imageRef.width
            let originalHeight = imageRef.height
            let bitsPerComponent = imageRef.bitsPerComponent
            let bytesPerRow = originalHeight * 4 // imageRef.bytesPerRow
            let colorSpace = imageRef.colorSpace
            let bitmapInfo = imageRef.bitmapInfo
            
            let radians = 1.5708 // = +90° //degreesToRotate(degreesToRotate)
            
            // Swap width/height
            let width = originalHeight
            let height = originalWidth
            
            print("size: " + String(describing: originalWidth) + " -- " + String(describing: originalHeight))
            print ("bit per component: " + String(describing: bitsPerComponent))
            print ("bit per row: " + String(describing: bytesPerRow))
            
            // bitmap = CGBitmapContextCreate(NULL, targetWidth, targetHeight, CGImageGetBitsPerComponent(imageRef), 0, colorSpaceInfo, bitmapInfo);
            
            let contextRef = CGContext(data: nil, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace!, bitmapInfo: bitmapInfo.rawValue)
            contextRef!.translateBy(x: CGFloat(width) / 2.0, y: CGFloat(height) / 2.0)
            
            contextRef!.rotate(by: CGFloat(radians))
            // swap
            contextRef!.translateBy(x: -CGFloat(height) / 2.0, y: -CGFloat(width) / 2.0)
            
            // redraw the img
            contextRef?.draw(imageRef, in: CGRect(x: 0, y: 0, width: CGFloat(originalWidth), height: CGFloat(originalHeight)))
            orientedImage = contextRef!.makeImage()
            
            print("cgImage size: " + String(describing: orientedImage?.width) + " --- " +  String(describing: orientedImage?.height) )
            
        }
        
        return orientedImage
    }
    
    
    
    
    // return a UIImage from CVPixelBuffer
    //
    func UIImageFromPixelBuffer(pixelBuffer: CVPixelBuffer) {
        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        let ctx = CIContext()
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let sizeImg  = CGSize(width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer))
        let cgImage = ctx.createCGImage(ciImage, from: CGRect(x: 0, y: 0, width: CGFloat(sizeImg.width), height: CGFloat(sizeImg.height)))
        let image = UIImage(cgImage: cgImage!)
        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        print("orientation: " + Tools.getOrientation(o: image.imageOrientation))
        
    }
    
    
    
    // Create a CVPixelBuffer, from a UIImage
    //
    func UIImageToPixelBuffer(image: UIImage)  -> CVPixelBuffer {
        let ciImage = CIImage(image: image)
        let context = CIContext(options: nil)
        let cgImage = context.createCGImage(ciImage!, from: ciImage!.extent)
        let pixelBuffer = CGImageToPixelBuffer(image: cgImage!)
        return pixelBuffer
    }
    
    
    
    // Create a CVPixelBuffer, from a CGImage
    //
    public func CGImageToPixelBuffer(image: CGImage) -> CVPixelBuffer {
        
        let frameSize = CGSize(width: CGFloat(image.width), height: CGFloat(image.height))
        
        // stupid CFDictionary stuff
        //        let keys: [CFString] = [kCVPixelBufferCGImageCompatibilityKey, kCVPixelBufferCGBitmapContextCompatibilityKey]
        //        let values: [CFTypeRef] = [kCFBooleanTrue, kCFBooleanTrue]
        //        let keysPointer = UnsafeMutablePointer<UnsafePointer. //.allocate(capacity: 1)
        //        let valuesPointer =  UnsafeMutablePointer<UnsafePointer.allocate(capacity: 1)
        //        keysPointer.initialize(to: keys)
        //        valuesPointer.initialize(to: values)
        
        let options: CFDictionary? = nil
        // let options = CFDictionaryCreate(kCFAllocatorDefault, keysPointer, valuesPointer, keys.count, UnsafePointer<CFDictionaryKeyCallBacks>(), UnsafePointer<CFDictionaryValueCallBacks>())
        
        //let buffer = UnsafeMutablePointer<CVPixelBuffer?>.allocate(capacity: 1)
        var buffer: CVPixelBuffer? = nil
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(frameSize.width), Int(frameSize.height), kCVPixelFormatType_32ARGB, options, &buffer)
        //print("CGImageToPixelBuffer status: " + String(describing: status))
        
        CVPixelBufferLockBaseAddress(buffer!, CVPixelBufferLockFlags(rawValue: 0));
        let bufferData = CVPixelBufferGetBaseAddress(buffer!);
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB();
        let context = CGContext(data: bufferData, width: Int(frameSize.width),
                                height: Int(frameSize.height), bitsPerComponent: 8, bytesPerRow: 4*Int(frameSize.width), space: rgbColorSpace,
                                bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue);
        
        context?.draw(image, in: CGRect(x: 0, y: 0, width: CGFloat(image.width), height: CGFloat(image.height))) //, byTiling: image)
        
        CVPixelBufferUnlockBaseAddress(buffer!, CVPixelBufferLockFlags(rawValue: 0));
        return buffer! //.memory!
    }
    
    
    
    
    
    // Create an empty image, with a specified size
    //
    static func imageWithSize(width:  CGFloat, height: CGFloat, filledWithColor color: UIColor = UIColor.clear, scale: CGFloat = 0.0, opaque: Bool = false) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: width, height: height)
        UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), opaque, scale)
        color.set()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
    
    
    
    
    
    //            UIGraphicsBeginImageContext(image.size)
    //            //image.drawHierarchy(in: self.view.bounds , afterScreenUpdates: false)
    //            let img:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
    //            UIGraphicsEndImageContext()
    //            let rect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
    //            let imageRef:CGImage = image.cgImage!.cropping(to: rect)!
    //            let cropped:UIImage = UIImage(cgImage:imageRef) //, scale: 1.0, orientation:UIImageOrientation.up)
    
    
    //            let rect = CGRect(x: 0,y: 0, width: image.size.width, height: image.size.height)
    //            let imageRef:CGImage = image.cgImage!.cropping(to: rect)!
    //            let cropped:UIImage = UIImage(cgImage:imageRef)
    //
    //            UIGraphicsBeginImageContext(cropped.size)
    //            let context = (UIGraphicsGetCurrentContext()!)
    //            //context.rotate(by: -90 / 180 * .pi)
    //            //cropped.draw(at: CGPoint(x: CGFloat(0), y: CGFloat(0)))
    //            //let img = UIGraphicsGetImageFromCurrentImageContext()!
    //            UIGraphicsEndImageContext()
    
    
    
    // create an image, with orientation = diffrente from original one.
    // pixel stay like original image
    //
    func createMatchingBackingDataWithImage(imageRef: CGImage?, orientation: UIImageOrientation) -> CGImage?
    {
        var orientedImage: CGImage?
        
        if let imageRef = imageRef {
            
            let originalWidth = imageRef.width
            let originalHeight = imageRef.height
            let bitsPerComponent = imageRef.bitsPerComponent
            let bytesPerRow = imageRef.bytesPerRow
            
            let colorSpace = imageRef.colorSpace
            let bitmapInfo = imageRef.bitmapInfo
            
            var degreesToRotate: Double
            var swapWidthHeight: Bool
            var mirrored: Bool
            switch orientation {
            case .up:
                degreesToRotate = 0.0
                swapWidthHeight = false
                mirrored = false
                break
            case .upMirrored:
                degreesToRotate = 0.0
                swapWidthHeight = false
                mirrored = true
                break
            case .right:
                degreesToRotate = 90.0
                swapWidthHeight = true
                mirrored = false
                break
            case .rightMirrored:
                degreesToRotate = 90.0
                swapWidthHeight = true
                mirrored = true
                break
            case .down:
                degreesToRotate = 180.0
                swapWidthHeight = false
                mirrored = false
                break
            case .downMirrored:
                degreesToRotate = 180.0
                swapWidthHeight = false
                mirrored = true
                break
            case .left:
                degreesToRotate = -90.0
                swapWidthHeight = true
                mirrored = false
                break
            case .leftMirrored:
                degreesToRotate = -90.0
                swapWidthHeight = true
                mirrored = true
                break
            }
            
            let radians = degreesToRotate * .pi / 180 // -1.5708 = 90° //degreesToRotate(degreesToRotate)
            
            var width: Int
            var height: Int
            if swapWidthHeight {
                width = originalHeight
                height = originalWidth
            } else {
                width = originalWidth
                height = originalHeight
            }
            
            let contextRef = CGContext(data: nil, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace!, bitmapInfo: bitmapInfo.rawValue)
            contextRef!.translateBy(x: CGFloat(width) / 2.0, y: CGFloat(height) / 2.0)
            if mirrored {
                contextRef!.scaleBy(x: -1.0, y: 1.0)
            }
            contextRef!.rotate(by: CGFloat(radians))
            if swapWidthHeight {
                contextRef!.translateBy(x: -CGFloat(height) / 2.0, y: -CGFloat(width) / 2.0)
            } else {
                contextRef!.translateBy(x: -CGFloat(width) / 2.0, y: -CGFloat(height) / 2.0)
            }
            //CGContextDrawImage(contextRef, CGRect(x: 0.0, y: 0.0, width: CGFloat(originalWidth), height: CGFloat(originalHeight)), imageRef)
            contextRef?.draw(imageRef, in: CGRect(x: 0, y: 0, width: CGFloat(originalWidth), height: CGFloat(originalHeight)))
            orientedImage = contextRef!.makeImage()
        }
        
        return orientedImage
    }
    
    
    // change orientation of an image
    // note : do not work. pixel are empty
    //
    func rotate(_ src: UIImage, andOrientation orientation: UIImageOrientation) -> UIImage {
        
        UIGraphicsBeginImageContext(src.size)
        let context = (UIGraphicsGetCurrentContext()!)
        if orientation == .right {
            context.rotate(by: 90 / 180 * .pi)
        }
        else if orientation == .left {
            context.rotate(by: -90 / 180 * .pi)
        }
        else if orientation == .down {
            // NOTHING
        }
        else if orientation == .up {
            context.rotate(by: 90 / 180 * .pi)
        }
        
        src.draw(at: CGPoint(x: CGFloat(0), y: CGFloat(0)))
        let img = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return img
    }
    
    
    
    
    
    
    // Deep copy of a pixelBuffer
    //
    func copyPixelBuffer(pixelBuffer: CVPixelBuffer) -> CVPixelBuffer{
        //var pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        // Get pixel buffer info
        //let kBytesPerPixel = 4
        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        let bufferWidth = Int(CVPixelBufferGetWidth(pixelBuffer))
        let bufferHeight = Int(CVPixelBufferGetHeight(pixelBuffer))
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let baseAddress: UnsafeMutableRawPointer = CVPixelBufferGetBaseAddress(pixelBuffer)!
        
        // Copy the pixel buffer
        var pixelBufferCopy: CVPixelBuffer? = nil
        let status = CVPixelBufferCreate(kCFAllocatorDefault, bufferWidth, bufferHeight, kCVPixelFormatType_32BGRA, nil, &pixelBufferCopy)
        CVPixelBufferLockBaseAddress(pixelBufferCopy!, CVPixelBufferLockFlags(rawValue: 0))
        let copyBaseAddress: UnsafeMutableRawPointer = CVPixelBufferGetBaseAddress(pixelBufferCopy!)!
        memcpy(copyBaseAddress, baseAddress, bufferHeight * bytesPerRow)
        
        return pixelBufferCopy!
    }
    
    
    
    
    // add a viewcontroller replacing the current view
    // editEdgesPoints = self.storyboard?.instantiateViewController(withIdentifier: "UIVC_EditEdgesPoints") as! UIVC_EditEdgesPoints?
    
    
    
    //    var timer: Timer!
    //timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.timerDelegate), userInfo: nil, repeats: true);
    //    func timerDelegate() {
    //        DispatchQueue.main.async {
    //        }
    //    }
    
    
    
}
