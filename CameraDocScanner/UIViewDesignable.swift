//
//  UIViewDesignable.swift
//  Camera_SCanner_IPDF_Proto
//
//  Created by Olivier Robin on 23/11/2016.
//  Copyright © 2016 Olivier Robin. All rights reserved.
//

import Foundation
import UIKit

class UIViewDesignable: UIView {
    
    @IBInspectable var cornerRadius: CGFloat = 0 {
        didSet {
            layer.cornerRadius = cornerRadius
            layer.masksToBounds = cornerRadius > 0
        }
    }
    @IBInspectable var borderWidth: CGFloat = 0 {
        didSet {
            layer.borderWidth = borderWidth
        }
    }
    @IBInspectable var borderColor: UIColor? {
        didSet {
            layer.borderColor = borderColor?.cgColor
        }
    }
    
}

