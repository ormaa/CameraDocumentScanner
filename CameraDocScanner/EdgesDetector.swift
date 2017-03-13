//
//  IPDFEdgesDetector.swift
//  Camera_SCanner_IPDF_Proto
//
//  Created by Olivier Robin on 22/11/2016.
//  Copyright © 2016 Olivier Robin. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import CoreImage
import ImageIO


//
// Conversion of IPDFCameraView.m by Olivier Robin
//


class RectangleFeature {
    var topLeft: CGPoint?
    var topRight: CGPoint?
    var bottomLeft: CGPoint?
    var bottomRight: CGPoint?
}


class EdgesDetector
{
    var borderDetected = false
    
    // detect rectangle around a document, inside an image
    // depending on the orientation, the edges need to be rotated
    //
    func startDetection(pixelBuffer: CVPixelBuffer) -> RectangleFeature?{
        borderDetected  = false
        
        // force image orientation to up
        // allowing to the rectangle detector to prpvide edges in the proper orientations
        let image = CIImage(cvPixelBuffer: pixelBuffer) //.applyingOrientation( Int32(CGImagePropertyOrientation.up.rawValue) ) // 2
        
        let borderDetectLastRectangleFeature =
            self.biggestRectangleInRectangles( rectangles: self.highAccuracyRectangleDetector().features(in: image) as! [CIRectangleFeature])
        
        
        // build a rectangle object to be returned
        let rect = RectangleFeature()
        if borderDetectLastRectangleFeature != nil {
            let b = borderDetectLastRectangleFeature!
            
            // note : rectangle detection consider the image in landscape mode !
            rect.topLeft = CGPoint(x: b.topLeft.x, y:  b.topLeft.y)
            rect.topRight = CGPoint(x: b.topRight.x, y: b.topRight.y)
            rect.bottomLeft = CGPoint(x: b.bottomLeft.x, y: b.bottomLeft.y)
            rect.bottomRight = CGPoint(x: b.bottomRight.x, y:  b.bottomRight.y)
            
            borderDetected = true
            //            print("IPDFEdgesDetector Edges : " + String(describing: b.topLeft) + " -- " +
            //                String(describing: b.topRight) + " -- " +
            //                String(describing: b.bottomLeft) + " -- " +
            //                String(describing: b.bottomRight) )
            
            return rect
        }
        else {
            
            // note the order to the point, needed here
            // because when edges discovered above, the real point position in the image are like this, below
            //
            let sizeImg  = CGSize(width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer))
            rect.topLeft = CGPoint(x: sizeImg.width, y:  sizeImg.height)
            rect.topRight  = CGPoint(x: sizeImg.width, y: 0)
            rect.bottomLeft = CGPoint(x: 0, y: sizeImg.height)
            rect.bottomRight = CGPoint(x: 0, y:  0)
            
            //            print("Edges from picture : " + String(describing: rect.topLeft!) + " -- " +
            //                String(describing: rect.topRight!) + " -- " +
            //                String(describing: rect.bottomLeft!) + " -- " +
            //                String(describing: rect.bottomRight!) )
            
            return rect // nil
        }
        
    }
    
    
    
    var detector: CIDetector? = nil
    // Create a rectangle detector, with highaccuracy
    //
    func highAccuracyRectangleDetector() -> CIDetector {
        detector = CIDetector(ofType: CIDetectorTypeRectangle, context: nil, options: [CIDetectorAccuracy : CIDetectorAccuracyHigh])
        return detector!
    }
    
    
    // sort points or rectangles found inside a picture
    //
    func biggestRectangleInRectangles(rectangles: [CIRectangleFeature]) -> CIRectangleFeature? {
        if rectangles.count == 0 { return nil }
        
        let rectangleFeature:CIRectangleFeature? = self._biggestRectangleInRectangles(rectangles: rectangles)!
        
        if rectangleFeature == nil { return nil }
        
        // Credit: http://stackoverflow.com/a/20399468/1091044
        // Conversion in swift : Olivier Robin - ORMAA.fr
        
        var points = [rectangleFeature?.topLeft, rectangleFeature?.topRight, rectangleFeature?.bottomLeft, rectangleFeature?.bottomRight]
        
        var min = points[0]!
        var max = min
        for value: CGPoint? in points {
            let point = value!
            min.x = CGFloat(fminf(Float(point.x), Float(min.x)))
            min.y = CGFloat(fminf(Float(point.y), Float(min.y)))
            max.x = CGFloat(fmaxf(Float(point.x), Float(max.x)))
            max.y = CGFloat(fmaxf(Float(point.y), Float(max.y)))
        }
        
        let center = CGPoint(x: 0.5 * (min.x + max.x), y: 0.5 * (min.y + max.y))
        
        let sortedPoints = getSortedPoints(center: center, points: points as! [CGPoint])
        
        let rectangleFeatureMutable = RectangleFeature()
        rectangleFeatureMutable.topLeft = sortedPoints[3]
        rectangleFeatureMutable.topRight = sortedPoints[2]
        rectangleFeatureMutable.bottomRight = sortedPoints[1]
        rectangleFeatureMutable.bottomLeft = sortedPoints[0]
        
        return rectangleFeature
    }
    
    
    // Calculate the angle between 2 vectors
    //
    func getAngleFromPoint(center: CGPoint, point: CGPoint) -> CGFloat
    {
        let theta = CGFloat( atan2f( Float(point.y - center.y), Float(point.x - center.x)) )
        let angle = CGFloat( fmodf( Float(Float(M_PI - M_PI_4) + Float(theta) ) , Float(2 * M_PI) ) )
        return angle as CGFloat
    }
    
    // get points sorted, ascending
    //
    func getSortedPoints(center: CGPoint, points: [CGPoint]) ->[CGPoint]{
        
        //        let sortedPoints = (points as NSArray).sortedArray(usingComparator: {(_ a: NSValue, _ b: NSValue) -> ComparisonResult in
        //            let p = self.getAngleFromPoint(center: center, point: a as CGPoint ).compare(self.getAngleFromPoint(center: center, point: (b as NSValue) as CGPoint))
        //            return p
        //        } as! (Any, Any) -> ComparisonResult)
        let sortedPoints = points.sorted { self.getAngleFromPoint(center: center, point: $0.0) > self.getAngleFromPoint(center: center, point: $0.1) }
        return sortedPoints
    }
    
    // Sort rectangles
    func _biggestRectangleInRectangles(rectangles: [CIRectangleFeature]) -> CIRectangleFeature? {
        
        if rectangles.count == 0 { return nil }
        
        var halfPerimiterValue: CGFloat = 0
        
        var biggestRectangle = rectangles.first
        for rect: CIRectangleFeature in rectangles {
            let p1 = rect.topLeft
            let p2 = rect.topRight
            let width: CGFloat = CGFloat(hypotf(Float(p1.x - p2.x), Float(p1.y - p2.y)))
            let p3 = rect.topLeft
            let p4 = rect.bottomLeft
            let height: CGFloat = CGFloat( hypotf(Float(p3.x - p4.x), Float(p3.y - p4.y)))
            let currentHalfPerimiterValue: CGFloat = height + width
            if halfPerimiterValue < currentHalfPerimiterValue {
                halfPerimiterValue = currentHalfPerimiterValue
                biggestRectangle = rect
            }
        }
        return biggestRectangle
    }
    
    
    
    
}

