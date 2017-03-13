//
//  EditEdgesPointsViewController.swift
//  CameraDocumentScanner
//
//  Created by Olivier Robin on 15/11/2016.
//  Copyright © 2016 olivier. All rights reserved.
//

import Foundation

import UIKit
import AVKit
import AVFoundation

class UIVC_EditEdgesPoints: UIViewController {
    
    
    
    // image, containing a document
    @IBOutlet weak var imageView: UIImageView!
    // edges of the document
    @IBOutlet weak var edgesView: EditableEdgesView!
    // small image, with zoomed part of the image, bellow the user finger
    // when he move a circle
    @IBOutlet weak var zoomedImage: UIImageView!
    
    @IBOutlet weak var activityAnimation: UIActivityIndicatorView!
    
    @IBOutlet weak var zoomedImageLeft: NSLayoutConstraint!
    @IBOutlet weak var zoomedImageTop: NSLayoutConstraint!
    
    @IBOutlet weak var imageViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var edgesViewTopConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var fondBordeaux: UIView!
    
    
    // image, filled by caller
    var image: UIImage?
    
    // Delegate to callback and send the quadrilateral updated
    var delegate: CropAndTransformImageProtocol?
    
    let edgesDetection = EdgesDetection()
    var threadCropAlive = true
    var quadrilateral: Quadrilateral?
    
    override func viewDidLoad() {
        zoomedImage.isHidden = true
        startWait()
        
        activityAnimation.transform = CGAffineTransform(scaleX: 2, y: 2)
        
        if !UIDevice.current.model.hasPrefix( "iPad") {
            imageViewTopConstraint.constant = 25
            edgesViewTopConstraint.constant = 25
        }
        else {
            fondBordeaux.isHidden = true
        }
        
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        
        print("edit edges - view bounds : " + String(describing: self.view.bounds))
        
        print("UIVC_EditEdgesPoints image source orientation: " + Tools.getOrientation(o: (image?.imageOrientation)!))
        
        let backgroundQueue = DispatchQueue(label: "fr.ormaa.app", qos: .background, target: nil)
        backgroundQueue.async {
            
            // start the edges detection on the still image
            
            // transform + crop the image
            let transform = ImageTransform()
            let temp = transform.Transform(image: self.image!)
            //let temp = transform.DetectCropTransform(image: image!)
            
            // Detect edges
            let tools = Tools()
            let pixelBuffer = tools.CGImageToPixelBuffer(image: (self.image?.cgImage)!)
            let edgesDetection = EdgesDetection()
            let quadrilateral = edgesDetection.startEdgesDetection(pixelBuffer: pixelBuffer)
            
            print("UIVC_EditEdgesPoints rotated image orientation: " + Tools.getOrientation(o: (temp?.imageOrientation)!))
            
            self.quadrilateral = quadrilateral!
            
            // check if quadrilateral is = to the image bounds
            if !edgesDetection.borderDetected {
                // the point oare = to the image bounds. move it slightly,
                // because the point on corner are difficult to handle with finger
                let offset = CGFloat(70)
                quadrilateral?.point1?.x -= offset
                quadrilateral?.point3?.x += offset
                quadrilateral?.point1?.y -= offset
                quadrilateral?.point3?.y -= offset
                
                quadrilateral?.point2?.x -= offset
                quadrilateral?.point4?.x += offset
                quadrilateral?.point2?.y += offset
                quadrilateral?.point4?.y += offset
            }
            
            DispatchQueue.main.async {
                // display the rotated image, ful size
                self.imageView.image = temp
                
                // display the edges, witht the points found
                self.drawEdges(quadrilateral: quadrilateral!)
                
                self.stopWait()
            }
            
            self.threadCropAlive = true
            Thread.detachNewThreadSelector(#selector(self.threadStartCrop), toTarget: self, with: nil)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        threadCropAlive = false
    }
    func startWait() {
        Thread.detachNewThreadSelector(#selector(self.threadStartAnimating), toTarget: self, with: nil)
    }
    func threadStartAnimating(_ data: Any) {
        self.activityAnimation.startAnimating()
    }
    func stopWait() {
        DispatchQueue.main.async {
            self.activityAnimation.stopAnimating()
        }
    }
    
    // Close this View controller
    //
    @IBAction func closeBtnClick(_ sender: Any) {
        // go to previous view
        self.dismiss(animated: true, completion: nil)
        // go back to first view
        //        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        //        let vc = storyboard.instantiateViewControllerWithIdentifier("FirstView") as! TableViewController
        //        self.presentViewController(vc, animated: true, completion: nil)
    }
    
    
    
    // save the result and close the view controller
    // save the points
    // save the document
    //
    @IBAction func okBtnClick(_ sender: Any) {
        
        print(" ")
        print("click ok, will crop the image")
        
        let tools = Tools()
        let pixelBuffer = tools.CGImageToPixelBuffer(image: (image?.cgImage)!)
        
        // compute the scale, and offset, allowing to know where the image is placed, in the UIView
        let sizeImg  = CGSize(width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer))
        // Scale
        let scaleX = (Float)(self.edgesView.frame.width / sizeImg.height)
        let scaleY = (Float)(self.edgesView.frame.height / sizeImg.width)
        print ("scale : " + String(describing: scaleX) + " / " + String(describing: scaleY) )
        
        //        // offset of the image, in the uiview
        //        var scale = CGFloat(scaleY)
        //        if scaleX < scaleY {
        //            scale = CGFloat(scaleX)
        //        }
        
        // offset of the image, in the uiview
        var offsetY: CGFloat = 0.0
        var offsetX: CGFloat = 0.0
        var scale = CGFloat(scaleY)
        if scaleX < scaleY {
            scale = CGFloat(scaleX)
        }
        let w = sizeImg.height * CGFloat(scale)
        offsetX = self.edgesView.frame.width - w
        let h = sizeImg.width * CGFloat(scale)
        offsetY = self.edgesView.frame.height - h
        
        offsetX = offsetX / 2
        offsetY = offsetY / 2
        
        // this can happen only on ipad.
        // in portrait, there is no offset to apply, because ipad is 4/3 preview full screen
        let orientation = UIDevice.current.orientation
        if orientation == .portraitUpsideDown || orientation == .portrait {
            offsetX = 0
            offsetY = 0
        }
        
        if scaleX < scaleY {
            offsetX = 0
        }
        else {
            offsetY = 0
        }
        
        print ("offset : " + String(describing: offsetX) + " / " + String(describing: offsetY) )
        
        // edges were shifted for the display. shift it back
        
        var q = edgesView.quadrilateral!
        let p1 = CGPoint(x: CGFloat( (q.point1!.y - offsetY) / scale), y: CGFloat( (q.point1!.x - offsetX) / scale))
        let p2 = CGPoint(x: CGFloat( (q.point2!.y - offsetY) / scale), y: CGFloat( (q.point2!.x - offsetX) / scale))
        let p3 = CGPoint(x: CGFloat( (q.point3!.y - offsetY) / scale), y: CGFloat( (q.point3!.x - offsetX) / scale))
        let p4 = CGPoint(x: CGFloat( (q.point4!.y - offsetY) / scale), y: CGFloat( (q.point4!.x - offsetX) / scale))
        print( "edges edited: " + String(describing: p1) + " -- " + String(describing: p2) + " -- " + String(describing: p3) + " -- " + String(describing: p4) )
        
        q = Quadrilateral(p1: p1, p2: p2, p3: p3, p4: p4)
        delegate?.cropAndTransformImage(quadrilateral: q)
        closeBtnClick( UIButton())
        
    }
    
    
    
    
    
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        print("didRotate")
        
        drawEdges(quadrilateral: self.quadrilateral!)
    }
    
    
    
    // edges found. display the edges
    //
    func drawEdges(quadrilateral: Quadrilateral) {
        let tools = Tools()
        let pixelBuffer = tools.CGImageToPixelBuffer(image: (image?.cgImage)!)
        
        // Note:
        // still image (compared to camera preview) are right oriented (landscape)
        // x and y are swapped
        // y is starting from bottom left !
        // BUT : image is displayed in portrait : width x height !
        
        // compute scale of the image : full size compared to display size
        let sizeImg  = CGSize(width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer))
        let scaleX = (Float)(self.edgesView.frame.width / sizeImg.height)
        let scaleY = (Float)(self.edgesView.frame.height / sizeImg.width)
        
        print("drawEdges image size: " + String(describing: sizeImg))
        print("drawEdges edgesView size: " + String(describing: self.edgesView.frame.size))
        print ("scale : " + String(describing: scaleX) + " / " + String(describing: scaleY) )
        
        // offset of the image, in the uiview
        var offsetY: CGFloat = 0.0
        var offsetX: CGFloat = 0.0
        var scale = CGFloat(scaleY)
        if scaleX < scaleY {
            scale = CGFloat(scaleX)
        }
        let w = sizeImg.height * CGFloat(scale)
        offsetX = self.edgesView.frame.width - w
        let h = sizeImg.width * CGFloat(scale)
        offsetY = self.edgesView.frame.height - h
        
        offsetX = offsetX / 2
        offsetY = offsetY / 2
        
        // this can happen only on ipad.
        // in portrait, there is no offset to apply, because ipad is 4/3 preview full screen
        let orientation = UIDevice.current.orientation
        if orientation == .portraitUpsideDown || orientation == .portrait {
            offsetX = 0
            offsetY = 0
        }
        
        if scaleX < scaleY {
            offsetX = 0
        }
        else {
            offsetY = 0
        }
        
        print ("offset : " + String(describing: offsetX) + " / " + String(describing: offsetY) )
        
        
        // rotate the point by 90° -> y = x, x = y
        let p1 = CGPoint(x: quadrilateral.point1!.y, y: quadrilateral.point1!.x)
        let p2 = CGPoint(x: quadrilateral.point2!.y, y: quadrilateral.point2!.x)
        let p3 = CGPoint(x: quadrilateral.point3!.y, y: quadrilateral.point3!.x)
        let p4 = CGPoint(x: quadrilateral.point4!.y, y: quadrilateral.point4!.x)
        
        // request to draw a rect, using the points p1 to p4
        var quad: Quadrilateral?
        quad = Quadrilateral(p1: CGPoint(x: offsetX + CGFloat(p1.x * scale), y: offsetY + CGFloat(p1.y * scale)),
                             p2: CGPoint(x: offsetX + CGFloat(p2.x * scale), y: offsetY + CGFloat(p2.y * scale)),
                             p3: CGPoint(x: offsetX + CGFloat(p3.x * scale), y: offsetY + CGFloat(p3.y * scale)),
                             p4: CGPoint(x: offsetX + CGFloat(p4.x * scale), y: offsetY + CGFloat(p4.y * scale)))
        
        print( "edges editing: " + String(describing: p1) + " -- " + String(describing: p2) + " -- " + String(describing: p3) + " -- " + String(describing: p4) )
        
        
        self.edgesView.quadrilateral = quad
        
        DispatchQueue.main.async {
            self.edgesView.setNeedsDisplay()
        }
    }
    
    
    
    
    
    
    var numPointToMove = 0
    // click on a point to move ?
    //
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        //print("touche began")
        if let touch = touches.first {
            let point = touch.location(in: edgesView)
            //let point2 = touch.view?.convert(point, to: nil)
            
            //print("point: " + String(describing: point))
            //print("point2: " + String(describing: point2!))
            
            numPointToMove = -1
            var cpt = 0
            for layer in edgesView.layers {
                if layer.path!.contains(point) {
                    //print("click on point: " + String(describing: cpt))
                    numPointToMove = cpt
                    let p = edgesView.getQuadrilateralPoint(num: numPointToMove)
                    moveZoomedImage(point: p!)
                }
                cpt += 1
            }
        }
        
        super.touchesBegan(touches, with: event)
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        zoomedImage.isHidden = true
    }
    
    
    // move a point
    //
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        //print("touche moved")
        if let touch = touches.first {
            
            let newLocation = touch.location(in: edgesView)
            let prevLocation = touch.previousLocation(in: edgesView)
            
            
            if (numPointToMove != -1) {
                var p = edgesView.getQuadrilateralPoint(num: numPointToMove)
                p?.x += newLocation.x - prevLocation.x
                p?.y += newLocation.y - prevLocation.y
                
                if p!.x < CGFloat(0) { p!.x = CGFloat(0) }
                if p!.y < CGFloat(0) { p!.y = CGFloat(0) }
                if p!.x > self.edgesView.bounds.size.width { p!.x = self.edgesView.bounds.size.width }
                if p!.y > self.edgesView.bounds.size.height { p!.y = self.edgesView.bounds.size.height }
                
                edgesView.setQuadrilateralPoint(num: numPointToMove, point: p!)
                edgesView.setNeedsDisplay()
                
                point = p
                
            }
        }
        super.touchesBegan(touches, with: event)
    }
    
    
    var point: CGPoint?
    
    func threadStartCrop(_ data: Any) {
        repeat {
            DispatchQueue.main.async {
                if (self.point != nil) {
                    // update a zoomed image
                    let cropped = self.getPointAreaImage(point: self.point!)
                    if cropped != nil {
                        self.zoomedImage.image = cropped
                        self.point = nil
                    }
                }
            }
            usleep(100000) // 0.1 sec
        }
            while(threadCropAlive)
    }
    
    
    // move the zoomed image into a corner, oposite side of where the user click
    //
    func moveZoomedImage(point: CGPoint) {
        
        let zoomedImgSize = self.zoomedImage.bounds.width
        
        // DEpending on the point edited, move the zoomed image to oposite side of the screen
        let width = edgesView.frame.size.width
        let height = edgesView.frame.size.height
        var x = CGFloat(0)
        var y = CGFloat(0)
        if point.x < width / 2 {
            x = width - (zoomedImgSize + 10)
        }
        else {
            x = 10
        }
        if point.y < height / 2 {
            y = height - (zoomedImgSize + 10)
        }
        else {
            y = 10
        }
        
        let cropped = getPointAreaImage(point: point)
        zoomedImage.image = cropped
        
        // update the constraint = move the image
        zoomedImageTop.constant = y
        zoomedImageLeft.constant = x
        zoomedImage.isHidden = false
    }
    
    
    // return a part of the imageView
    //
    func getPointAreaImage(point: CGPoint) -> UIImage? {
        //print("point: " + String(describing: point))
        if isCropping {
            return nil
        }
        isCropping =  true
        
        let deltaY = imageView.frame.origin.y
        // Chooze a size larger than the screen, allowing to have proper zoomed + Cropped area, when point is on a border
        let size = CGSize(width: self.view.bounds.width , height: self.view.bounds.height)
        let bounds = CGRect(x: 0, y:0, width: size.width, height: size.height)
        
        // redraw the screen, in image object.
        UIGraphicsBeginImageContext(size) //self.view.frame.size)
        self.view?.drawHierarchy(in: bounds , afterScreenUpdates: true)
        let image:UIImage = UIGraphicsGetImageFromCurrentImageContext()!;
        UIGraphicsEndImageContext()
        
        // Get a cropped part of the image rendered
        // Get a small part, to force it to be zoomed ( zoom image is 96x96)
        var x =  point.x - 32
        var y = deltaY + point.y - 32
        if x < 0 { x = 0 }
        if y < 0 { y = 0 }
        if x > bounds.width - 64 { x = bounds.width - 64 }
        if y > bounds.height - 64 { y = bounds.height - 64 }
        
        let rect = CGRect(x: x,y: y, width: 64, height: 64)
        let imageRef:CGImage = image.cgImage!.cropping(to: rect)!
        let cropped:UIImage = UIImage(cgImage:imageRef)
        
        isCropping = false
        return cropped
    }
    
    
    
    var isCropping = false
    
    
    
}
