//
//  UIViewRect.swift
//  CameraDocumentScanner
//
//  Created by Olivier Robin on 10/11/2016.
//  Copyright © 2016 olivier. All rights reserved.
//

import Foundation
import UIKit

class EdgesView: UIView {
    
    var quadrilateral: Quadrilateral?
    var imageView: UIImageView?
    
    var computing = false
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    // separated refresh method, instead of  draw(...) is tested here, to check if it takes more time than classic draw(...) method
    // drw( method is used in EditableEdgesView class
    //
    
    func refresh(size: CGSize) {
        //let bounds = CGRect(origin: CGPoint.zero, size: size)
        if imageView != nil {
            imageView?.removeFromSuperview()
        }
        
        if quadrilateral == nil { return }
        
        // Draw a rect, using the points p1 to p4
        let quad = quadrilateral!
        
        let opaque = false
        let scale: CGFloat = 0
        
        // Setup context
        UIGraphicsBeginImageContextWithOptions(size, opaque, scale)
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        // define drawing values
        context.setStrokeColor(UIColor.green.cgColor)
        context.setLineWidth(4.0)
        context.setAlpha(0.4)
        
        // Would draw a border around the rectangle
        // context.stroke(bounds)
        
        // quadrilateral is filled with edges of document : topleft, topdright, bottomleft, bottomright
        
        context.beginPath()
        context.move(to: quad.point1!)
        context.addLine(to: quad.point2!)
        context.addLine(to: quad.point4!)
        context.addLine(to: quad.point3!)
        context.addLine(to: quad.point1!)
        context.strokePath()
        
        // Drawing complete, retrieve the finished image and cleanup
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        imageView = UIImageView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: size))
        imageView?.image = image
        self.addSubview(imageView!)

    }
    
}
