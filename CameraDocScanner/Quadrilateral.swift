//
//  Quadrilateral.swift
//  CameraDocumentScanner
//
//  Created by Olivier Robin on 15/11/2016.
//  Copyright © 2016 olivier. All rights reserved.
//

import Foundation
import UIKit

@objc class Quadrilateral: NSObject {
    
    var point1: CGPoint?
    var point2: CGPoint?
    var point3: CGPoint?
    var point4: CGPoint?
    
    @objc init( p1: CGPoint, p2: CGPoint, p3: CGPoint, p4: CGPoint) {
        self.point1 = p1
        self.point2 = p2
        self.point3 = p3
        self.point4 = p4
    }
}


