//
//  ImageTransform.swift
//  CameraDocScanner
//
//  Created by Olivier Robin on 23/11/2016.
//  Copyright © 2016 Olivier Robin All rights reserved.
//

import Foundation
import UIKit


public class ImageTransform
{
    public init() {
        
    }
    
    // 1°) get in uiimage : pixelBuffer
    //
    func getPixelBuffer(image: UIImage) -> CVPixelBuffer {
        let ciImage = CIImage(cgImage: image.cgImage!)
        
        // Apply a Contrast filter
        let filter = CIFilter(name:"CIColorControls")
        filter!.setValue(ciImage, forKey:kCIInputImageKey)
        filter!.setValue(1.1, forKey:"inputContrast")
        
        let contrasted = filter!.outputImage!
        
        // create cgImage
        let context = CIContext(options:nil)
        let cgimg = context.createCGImage(contrasted, from: contrasted.extent)
        // Create pixelBuffer
        let tools = Tools()
        let pixelBuffer = tools.CGImageToPixelBuffer(image: cgimg!)
        
        return pixelBuffer
    }
    
    
    // 2°) detect the edges of a document, in the pixel buffer
    //
    func detectEdges(pixelBuffer: CVPixelBuffer) -> Quadrilateral?{
        // Detect edges.
        let edgesDetection = EdgesDetection()
        let quadrilateral = edgesDetection.startEdgesDetection(pixelBuffer: pixelBuffer)
        if quadrilateral == nil {
            print("capture image : no edges found !")
            return nil
        }
        else {
            return quadrilateral
        }
    }
    
    
    // 3°) crop, tranform (pespective)
    //
    func cropAndTransform(image: UIImage, quadrilateral: Quadrilateral) ->UIImage  {
        let ciImage = CIImage(cgImage: image.cgImage!)
        
        // Apply a Contrast filter
        let filter = CIFilter(name:"CIColorControls")
        filter!.setValue(ciImage, forKey:kCIInputImageKey)
        filter!.setValue(1.1, forKey:"inputContrast")
        let contrasted = filter!.outputImage!
        
        // create cgImage
        let context = CIContext(options:nil)
        
        // transform the image to have a rectangle
        let q = quadrilateral
        var rectangleCoordinates = [String : Any]()
        rectangleCoordinates["inputTopLeft"] = CIVector(cgPoint: q.point1!)
        rectangleCoordinates["inputTopRight"] = CIVector(cgPoint: q.point2!)
        rectangleCoordinates["inputBottomLeft"] = CIVector(cgPoint: q.point3!)
        rectangleCoordinates["inputBottomRight"] = CIVector(cgPoint: q.point4!)
        let outputImage = contrasted.applyingFilter("CIPerspectiveCorrection", withInputParameters: rectangleCoordinates)
        
        // Create an uiimage
        let cgimg2 = context.createCGImage(outputImage, from: outputImage.extent)
        let uiimg = UIImage(cgImage: cgimg2!, scale:1, orientation: UIImageOrientation.down)
        //        let uiimg2 = UIImage(cgImage: uiimg.cgImage!, scale: 1.0, orientation: UIImageOrientation.up)
        
        
        return uiimg
        
        //        // the image is right oriented.
        //        // we need to create an image with same pixel buffer, but orientation = up
        //        let imageRef = cgimg2!
        //
        //        let originalWidth = imageRef.width
        //        let originalHeight = imageRef.height
        //        let bitsPerComponent = imageRef.bitsPerComponent
        //        let bytesPerRow = imageRef.bytesPerRow
        //        let colorSpace = imageRef.colorSpace
        //        let bitmapInfo = imageRef.bitmapInfo
        //
        //        let radians = -1.5708 // = -90°
        //
        //        // Swap width/height
        //        let width = originalHeight
        //        let height = originalWidth
        //
        //        print ("bit per component: " + String(describing: bitsPerComponent))
        //        print ("bit per row: " + String(describing: bytesPerRow))
        //
        //        // bitmap = CGBitmapContextCreate(NULL, targetWidth, targetHeight, CGImageGetBitsPerComponent(imageRef), 0, colorSpaceInfo, bitmapInfo);
        //        let contextRef = CGContext(data: nil, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace!, bitmapInfo: bitmapInfo.rawValue)
        //        contextRef!.translateBy(x: CGFloat(width) / 2.0, y: CGFloat(height) / 2.0)
        //        contextRef!.rotate(by: CGFloat(radians))
        //        // swap
        //        contextRef!.translateBy(x: -CGFloat(height) / 2.0, y: -CGFloat(width) / 2.0)
        //
        //        // redraw the img
        //        contextRef?.draw(imageRef, in: CGRect(x: 0, y: 0, width: CGFloat(originalWidth), height: CGFloat(originalHeight)))
        //        let orientedImage = contextRef!.makeImage()
        //        let uiimg2 = UIImage(cgImage: orientedImage!, scale: 1.0, orientation: UIImageOrientation.down)
        //
        //        return uiimg2
        
    }
    
    
    // transform a UIImage : change the perspective, depending on the edges of a document found inside this image
    //
    public func DetectCropTransform(image: UIImage) -> UIImage?{
        
        let ciImage = CIImage(cgImage: image.cgImage!)
        
        // Apply a Contrast filter
        let filter = CIFilter(name:"CIColorControls")
        filter!.setValue(ciImage, forKey:kCIInputImageKey)
        filter!.setValue(1.1, forKey:"inputContrast")
        let contrasted = filter!.outputImage!
        
        // Attention
        // an image, oriented right, with width = 2000, height = 3000, after filter =  oriented ??? with width = 3000, height = 2000
        
        print("ciImage size: " + String(describing: contrasted.extent))
        
        // create cgImage
        let context = CIContext(options:nil)
        let cgimg = context.createCGImage(contrasted, from: contrasted.extent)
        // Create pixelBuffer
        let tools = Tools()
        let pixelBuffer = tools.CGImageToPixelBuffer(image: cgimg!)
        // Detect edges.
        let edgesDetection = EdgesDetection()
        let quadrilateral = edgesDetection.startEdgesDetection(pixelBuffer: pixelBuffer)
        
        let sizeImg  = CGSize(width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer))
        print("full size image size: " + String(describing: sizeImg))
        
        
        // transform the image to have a rectangle
        let q = quadrilateral!
        var rectangleCoordinates = [String : Any]()
        rectangleCoordinates["inputTopLeft"] = CIVector(cgPoint: q.point1!)
        rectangleCoordinates["inputTopRight"] = CIVector(cgPoint: q.point2!)
        rectangleCoordinates["inputBottomLeft"] = CIVector(cgPoint: q.point3!)
        rectangleCoordinates["inputBottomRight"] = CIVector(cgPoint: q.point4!)
        let outputImage = contrasted.applyingFilter("CIPerspectiveCorrection", withInputParameters: rectangleCoordinates)
        
        // Create an uiimage
        let cgimg2 = context.createCGImage(outputImage, from: outputImage.extent)
        let uiimg = UIImage(cgImage: cgimg2!, scale:1, orientation: UIImageOrientation.down)
        return uiimg
    }
    
    
    
    
    // transform a UIImage : change the perspective. use bounds of the image
    // do not crop the image.
    // Allow to have exactly the same content compared to what is returned when image is cropped : orientation, contrast, etc...
    //
    public func Transform(image: UIImage) -> UIImage?{
        
        let ciImage = CIImage(cgImage: image.cgImage!)
        
        // Apply a Contrast filter
        let filter = CIFilter(name:"CIColorControls")
        filter!.setValue(ciImage, forKey:kCIInputImageKey)
        filter!.setValue(1.1, forKey:"inputContrast")
        let contrasted = filter!.outputImage!
        
        // create cgImage
        let context = CIContext(options:nil)
        
        let quadrilateral = Quadrilateral(
            p1: CGPoint(x: image.size.height, y: image.size.width) ,
            p2: CGPoint(x: image.size.height, y:  0) ,
            p3: CGPoint(x: 0, y:  image.size.width),
            p4: CGPoint(x: 0, y:  0))
        //        p1: CGPoint(x: image.size.width, y: image.size.height) ,
        //        p2: CGPoint(x: image.size.width, y:  0) ,
        //        p3: CGPoint(x: 0, y:  image.size.height),
        //        p4: CGPoint(x: 0, y:  0))
        
        // transform the image to have a rectangle
        let q = quadrilateral
        var rectangleCoordinates = [String : Any]()
        rectangleCoordinates["inputTopLeft"] = CIVector(cgPoint: q.point1!)
        rectangleCoordinates["inputTopRight"] = CIVector(cgPoint: q.point2!)
        rectangleCoordinates["inputBottomLeft"] = CIVector(cgPoint: q.point3!)
        rectangleCoordinates["inputBottomRight"] = CIVector(cgPoint: q.point4!)
        let outputImage = contrasted.applyingFilter("CIPerspectiveCorrection", withInputParameters: rectangleCoordinates)
        
        // Create an uiimage
        let cgimg2 = context.createCGImage(outputImage, from: outputImage.extent)
        let uiimg = UIImage(cgImage: cgimg2!, scale:1, orientation: UIImageOrientation.down)
        return uiimg
    }
    
    
    
}
