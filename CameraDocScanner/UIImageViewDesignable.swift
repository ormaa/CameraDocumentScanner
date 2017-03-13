//
//  UIViewDesignable.swift
//  SegescanApp
//
//  Created by Olivier Robin on 19/10/2016.
//  Copyright © 2016 ORMAA. All rights reserved.
//

import Foundation
import UIKit

class UIImageViewDesignable: UIImageView {
    
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
