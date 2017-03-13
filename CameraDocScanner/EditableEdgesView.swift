//
//  EditableEdgesView.swift
//  CameraDocumentScanner
//
//  Created by Olivier Robin on 15/11/2016.
//  Copyright © 2016 olivier. All rights reserved.
//

import Foundation
import UIKit

class EditableEdgesView: UIView {
    
    var quadrilateral: Quadrilateral?
    var layers:[CAShapeLayer] = []
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    
    override func draw(_ rect: CGRect) {
        
        if quadrilateral == nil {
            return
        }

        // Draw a rect, using the points p1 to p4
        //print("drawing rect")
        let quad = quadrilateral!

        let aPath = UIBezierPath()
        aPath.move(to: quad.point1!)
        aPath.addLine(to: quad.point2!)
        aPath.addLine(to: quad.point4!)
        aPath.addLine(to: quad.point3!)
        aPath.addLine(to: quad.point1!)
        aPath.close()
        UIColor.red.set()
        aPath.stroke()
        //aPath.fill()
        
        let layer = CAShapeLayer()
        layer.path = aPath.cgPath
        layer.fillColor = UIColor.clear.cgColor
        layer.opacity = 0.7
        self.layer.addSublayer(layer)
        
        // Delete previously created layers
        for layer in layers {
            layer.removeFromSuperlayer()
        }
        layers = []
        
        // Draw 4 circle, one for each edge
        layers.append( createCircle(point: quad.point1!, color: UIColor.red.cgColor))
        layers.append( createCircle(point: quad.point2!, color: UIColor.green.cgColor))
        layers.append( createCircle(point: quad.point3!, color: UIColor.yellow.cgColor))
        layers.append( createCircle(point: quad.point4!, color: UIColor.blue.cgColor))

        for layer in layers {
            self.layer.addSublayer(layer)
        }
    }
    
    
    func createCircle(point: CGPoint, color: CGColor) -> CAShapeLayer {
        //print("add layer: " + String(describing: point.x) + " / " + String(describing: point.y))
        let circlePath2 = UIBezierPath(arcCenter: point, radius: CGFloat(16), startAngle: CGFloat(0), endAngle: CGFloat(2*M_PI), clockwise: true)
        circlePath2.lineWidth = 2
        let layer = CAShapeLayer()
        layer.path = circlePath2.cgPath
        layer.fillColor = color // UIColor.red.cgColor
        layer.opacity = 0.4
        return layer
    }
    

    func getQuadrilateralPoint(num: Int) -> CGPoint? {
        if num == 0 {
            return (quadrilateral?.point1)!
        }
        if num == 1 {
            return (quadrilateral?.point2)!
        }
        if num == 2 {
            return (quadrilateral?.point3)!
        }
        if num == 3 {
            return (quadrilateral?.point4)!
        }
        return nil
    }
    
    func setQuadrilateralPoint(num: Int, point: CGPoint) {
        if num == 0 {
            quadrilateral?.point1 = point
        }
        if num == 1 {
            quadrilateral?.point2 = point
        }
        if num == 2 {
            quadrilateral?.point3 = point
        }
        if num == 3 {
            quadrilateral?.point4 = point
        }
    }
    
}
