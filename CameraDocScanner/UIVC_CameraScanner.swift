//
//  UIVC_CameraScanner.swift
//  CameraDocumentScanner
//
//  Created by Olivier Robin on 10/11/2016.
//  Copyright © 2016 olivier. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

protocol CameraScannerProtocol
{
    func DocumentCaptured(image: UIImage)
}

protocol CropAndTransformImageProtocol {
    func cropAndTransformImage(quadrilateral: Quadrilateral)
}

class UIVC_CameraScanner: UIViewController,
CameraControllerProtocol, CropAndTransformImageProtocol {
    
    
    // Draw a rectangle, when document edges is found
    @IBOutlet weak var edgesView: EdgesView!
    // contain a small image, when photo is captured
    @IBOutlet weak var smallImage: UIImageView!
    // contain the camera preview
    @IBOutlet weak var cameraPreview: UIView!
    // torch status label
    @IBOutlet weak var onOff: UILabel!
    @IBOutlet weak var viewSmallImage: UIViewDesignable!
    @IBOutlet weak var activityAnimation: UIActivityIndicatorView!
    @IBOutlet weak var cameraBtn: UIButtonDesignable!
    @IBOutlet weak var fondBordeaux: UIView!
    @IBOutlet weak var fondBordeaux2: UIView!
    
    // allow to preview camera, take still picture, set the torche mode
    var cameraController: CameraController?
    // edges detection class
    var edgesDetection: EdgesDetection?
    
    var imageCaptured: UIImage?
    var flashMode: AVCaptureFlashMode = .off
    
    var cameraScannerDelegate:CameraScannerProtocol?
    
    
    // View controller used to edit the edgs of a document
    var editEdgesPoints: UIVC_EditEdgesPoints?
    // computing flag used like singleton system
    var computing = false
    
    var capturingPhoto = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewSmallImage.isHidden = true
        cameraBtn.isEnabled = false // need this to be sure it is already disabled when image is displayed. in old phone, we can see it enabled during a short time.
        stopWait()
        
        // Tap gesture on smallImage
        let tapGestureRecognizer = UITapGestureRecognizer(target:self, action:#selector(imageTapped(img:)))
        smallImage.isUserInteractionEnabled = true
        smallImage.addGestureRecognizer(tapGestureRecognizer)
        
        activityAnimation.transform = CGAffineTransform(scaleX: 2, y: 2)
        
        if !UIDevice.current.model.hasPrefix( "iPad") {
            cameraBtn.backgroundColor = UIColor.white
        }
        else {
            fondBordeaux.isHidden = true
            fondBordeaux2.isHidden = true
        }
    }
    
    
    
    override func viewDidAppear(_ animated: Bool) {
        print("viewDidAppear - view size: " + String(describing: self.view.frame.size.width) + " / " + String(describing: self.view.frame.size.height))
        
        cameraBtn.isEnabled = false // need this, in case we come back from background
        edgesDetection = EdgesDetection()
        
        if cameraController != nil && cameraController!.previewStarted {
            // TODO ? resume ?
        }
        else {
            initCamera()
        }
    }
    
    
    func initCamera() {
        cameraController = CameraController()
        cameraController?.initCamera(delegate: self, previewUIView: self.cameraPreview, completion: { (alowedAccess) -> Void in
            if !alowedAccess {
                let ac = UIAlertController(title: "Attention",
                                           message: "Vous n'avez pas autorisé l'accès à votre Caméra !\nRendez vous dans le menu \nParamètres, puis\nConfidentialité/Appareil Photo\nAuthorisez Segescan à utiliser votre Caméra", preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "OK", style: .default))
                let goAction = UIAlertAction(title: "Paramètres", style: .default) {  (action) in
                    
                    //let url = NSURL(string: "prefs:root=Privacy&path=LOCATION")
                    //UIApplication.shared.openURL( url as! URL )
                    guard let settingsUrl = URL(string: UIApplicationOpenSettingsURLString) else {
                        return
                    }
                    UIApplication.shared.openURL(settingsUrl)
                    
                    
                }
                ac.addAction(goAction)
                
                self.present(ac, animated: true)
            }
        })
        
        cameraController?.setFlashMode(flashMode: .off)
        cameraController?.startSession()
        
        DispatchQueue.main.async {
            self.cameraController?.updateOrientation()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        cameraController?.stopSession()
    }
    
    
    
    
    func startWait() {
        Thread.detachNewThreadSelector(#selector(self.threadStartAnimating), toTarget: self, with: nil)
        usleep(500000) // 0.5 sec
    }
    func threadStartAnimating(_ data: Any) {
        self.activityAnimation.startAnimating()
    }
    
    func stopWait() {
        DispatchQueue.main.async {
            self.activityAnimation.stopAnimating()
        }
    }
    
    
    override func willRotate(to toInterfaceOrientation: UIInterfaceOrientation, duration:TimeInterval) {
        print("willRotate")
        cameraController?.stopSession()
    }
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        print("didRotate")
        initCamera()
        
        
        
    }
    
    
    
    
    
    
    
    
    // draw the edges of a document, found in the captured image, or preview image
    //
    internal func drawEdges(pixelBuffer: CVPixelBuffer, quadrilateral: Quadrilateral) {
        
        // compute the scale, and offset, allowing to know where the image is placed, in the UIView
        let sizeImg  = CGSize(width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer))
        //print("preview draw edges image size: " + String(describing: sizeImg))
        
        // edges are detected with an image upside down compare to what is visible on screen !
        let p1 = CGPoint(x: quadrilateral.point1!.x, y: sizeImg.height - quadrilateral.point1!.y)
        let p2 = CGPoint(x: quadrilateral.point2!.x, y: sizeImg.height - quadrilateral.point2!.y)
        let p3 = CGPoint(x: quadrilateral.point3!.x, y: sizeImg.height - quadrilateral.point3!.y)
        let p4 = CGPoint(x: quadrilateral.point4!.x, y: sizeImg.height - quadrilateral.point4!.y)
        
        // Scale
        let scaleX = (Float)(self.edgesView.frame.width / sizeImg.width)
        let scaleY = (Float)(self.edgesView.frame.height / sizeImg.height)
        //print ("scale : " + String(describing: scaleX) + " / " + String(describing: scaleY) )
        
        // offset of the image, in the uiview
        var offsetY: CGFloat = 0.0
        var offsetX: CGFloat = 0.0
        var scale = CGFloat(scaleY)
        if scaleX < scaleY {
            scale = CGFloat(scaleX)
        }
        let w = sizeImg.width * CGFloat(scale)
        offsetX = self.edgesView.frame.width - w
        let h = sizeImg.height * CGFloat(scale)
        offsetY = self.edgesView.frame.height - h
        offsetX = offsetX / 2
        offsetY = offsetY / 2
        //        print ("offset : " + String(describing: offsetX) + " / " + String(describing: offsetY) )
        
        // this can happen only on ipad.
        // in landscape, there is no offset to apply, because ipad is 4/3 preview full screen
        let orientation = UIDevice.current.orientation
        if orientation == .landscapeRight || orientation == .landscapeLeft {
            offsetX = 0
            offsetY = 0
        }
        
        // request to draw a rect, using the points p1 to p4
        
        var quad: Quadrilateral?
        
        quad = Quadrilateral(p1: CGPoint(x: offsetX + CGFloat(p1.x * scale), y: offsetY + CGFloat(p1.y * scale)),
                             p2: CGPoint(x: offsetX + CGFloat(p2.x * scale), y: offsetY + CGFloat(p2.y * scale)),
                             p3: CGPoint(x: offsetX + CGFloat(p3.x * scale), y: offsetY + CGFloat(p3.y * scale)),
                             p4: CGPoint(x: offsetX + CGFloat(p4.x * scale), y: offsetY + CGFloat(p4.y * scale)))
        
        self.edgesView.quadrilateral = quad
        
        DispatchQueue.main.async {
            self.edgesView.refresh(size: self.edgesView.frame.size)
            self.computing = false
        }
        
    }
    
    
    
    // user has taped on the small image
    // will edit the edges position of the document
    //
    func imageTapped(img: AnyObject)
    {
        viewSmallImage.isHidden = true
        //cameraController?.startSession()
        
        print("discard capture")
    }
    
    
    
    
    
    
    
}

