//
//  ViewController.swift
//  CameraExample
//
//  Created by Geppy Parziale on 2/15/16.
//  Copyright © 2016 iNVASIVECODE, Inc. All rights reserved.
//

import UIKit
import AVFoundation


public protocol CameraControllerProtocol {
    func cameraSessionPreview(sampleBuffer: CMSampleBuffer!)
    func pictureCaptured(image: UIImage)
}



public class CameraController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var previewUIView: UIView?
    var delegate: CameraControllerProtocol?
    public let stillImageOutput = AVCaptureStillImageOutput()

    public var cameraAuthorized = false
    public var previewStarted = false
    public var orientation:AVCaptureVideoOrientation?
    
    public func updateOrientation() {
        let orientation = UIDevice.current.orientation
        if previewLayer?.connection == nil {
            print("camera connection is nil. cannot update orientation...")
            return
        }
        
        switch (orientation) {
        case .landscapeLeft:
            print("preview orientation left")
            previewLayer?.connection.videoOrientation = .landscapeRight
            break;
        case .landscapeRight:
            print("preview orientation right")
            previewLayer?.connection.videoOrientation = .landscapeLeft
            break;
        case .portraitUpsideDown:
            print("preview orientation portraitUpsideDown")
            previewLayer?.connection.videoOrientation = .portraitUpsideDown
            break;
        default:
            print("preview orientation portrait")
            previewLayer?.connection.videoOrientation = .portrait
            break;
        }
        
        self.orientation = previewLayer?.connection.videoOrientation
    }
    
    // Capture a photo, using full resolution of the lens
    public func capturePhoto() -> Bool{
        
        if let videoConnection = stillImageOutput.connection(withMediaType: AVMediaTypeVideo) {
            videoConnection.videoOrientation = AVCaptureVideoOrientation.portrait
            
            stillImageOutput.captureStillImageAsynchronously(from: videoConnection) {
                (sampleBuffer, error) -> Void in
                print("photo captured")

                videoConnection.videoOrientation = AVCaptureVideoOrientation.portrait

                if (sampleBuffer == nil) {
                    print("capture photo is nil")
                    return
                }

                let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer)
                // Create an image. Note : it will have an orientation = right !
                let img = UIImage(data: imageData!)! //, scale: 1.0, orientation: UIImageOrientation.up)!
                print("photo captured orientation: " + Tools.getOrientation(o: img.imageOrientation))
                print("photo captured size : " + String(describing: img.size))
                
                self.delegate?.pictureCaptured(image: img)
            }
            return true
        }
        else {
            return false
        }
    }
    
    // set the flash mode when capturing still photo
    public func setFlashMode(flashMode: AVCaptureFlashMode) {
        
        do {
                        
            let captureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo) as AVCaptureDevice
            let deviceInput =  try AVCaptureDeviceInput(device: captureDevice).device
 
            print("set flash : " + String(flashMode.rawValue))
            
            if  (deviceInput?.hasTorch)! {
                try deviceInput?.lockForConfiguration()
                deviceInput?.flashMode = flashMode
                deviceInput?.unlockForConfiguration()
            }
        }
        catch {
                print("torch error")
        }
        
        
    }
    
    
    // init the camera session
    //
    public func initCamera(delegate: CameraControllerProtocol, previewUIView: UIView, completion: @escaping (Bool) -> Void) {
        
        self.delegate = delegate
        self.previewUIView = previewUIView
        
        askUserForCameraPermission({ permissionGranted in
            print("camera permission : " + String(describing: permissionGranted))
            if permissionGranted {
                self.setupCameraSession()
            }
            completion(permissionGranted)
        })

    }
    
    // Set orientation
    //let currentDevice: UIDevice = UIDevice.current
    //let orientation: UIDeviceOrientation = currentDevice.orientation
    //        if (previewLayerConnection?.isVideoOrientationSupported)! {
    //            if (previewLayerConnection?.isVideoOrientationSupported)! {
    //
    //                switch (orientation) {
    //                case .portrait: updatePreviewLayer(layer: previewLayerConnection!, orientation: .portrait)
    //                    break
    //                case .landscapeRight: updatePreviewLayer(layer: previewLayerConnection!, orientation: .landscapeLeft)
    //                    break
    //                case .landscapeLeft: updatePreviewLayer(layer: previewLayerConnection!, orientation: .landscapeRight)
    //                    break
    //                case .portraitUpsideDown: updatePreviewLayer(layer: previewLayerConnection!, orientation: .portraitUpsideDown)
    //                    break
    //                default: updatePreviewLayer(layer: previewLayerConnection!, orientation: .portrait)
    //                    break
    //                }
    //            }
    //        }
    
    
 
    
    // start to preview camera
    //
    public func startSession() {
        
        let s = AVCaptureSession()
        s.sessionPreset = AVCaptureSessionPresetPhoto // AVCaptureSessionPresetHigh //AVCaptureSessionPresetLow
        cameraSession = s
        
        stillImageOutput.outputSettings = [AVVideoCodecKey:AVVideoCodecJPEG]
        if cameraSession!.canAddOutput(stillImageOutput) {
            cameraSession!.addOutput(stillImageOutput)
        }
        
        //Get Preview Layer connection
        let preview =  AVCaptureVideoPreviewLayer(session: self.cameraSession)
        
        // Specify the bounds of the preview component in the view
        print("preview camera size: " + String(describing: self.previewUIView!.frame.width) + " -- " + String(describing: self.previewUIView!.frame.height))
        preview?.bounds = CGRect(x: 0, y: 0, width: (self.previewUIView?.frame.width)!, height: (self.previewUIView?.frame.height)!)
        preview?.anchorPoint = CGPoint(x: 50,y: 0)
        preview?.position = CGPoint(x: 20, y: 0) //self.view.bounds.midX, y: self.view.bounds.midY)
        preview?.videoGravity = AVLayerVideoGravityResize //AVLayerVideoGravityResizeAspect //AVLayerVideoGravityResize
        preview?.frame = CGRect(x: 0, y: 0, width: (self.previewUIView?.frame.width)!, height: (self.previewUIView?.frame.height)!)
        previewLayer = (preview)!
    
        cameraSession!.startRunning()
        previewStarted = true

        // Add the camera preview in the ui component
        previewUIView?.layer.addSublayer(previewLayer!)
    }
    
//    func updatePreviewLayer(layer: AVCaptureConnection, orientation: AVCaptureVideoOrientation) {
//        layer.videoOrientation = orientation
////          force the orientation, to portrait
////          layer.videoOrientation = AVCaptureVideoOrientation.portrait
////          layer.isVideoMirrored = false
////          previewLayer.frame = self.view.bounds
//    }
    
    public func stopSession() {
        previewLayer!.removeFromSuperlayer()
        cameraSession!.stopRunning()
        previewStarted = false
    }
    
    public func pauseSession() {
        cameraSession!.stopRunning()
    }
    public func resumeSession() {
        cameraSession!.startRunning()
    }
    
    // display a popup, requesting the use of the camera.
    func askUserForCameraPermission(_ completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo, completionHandler: { (alowedAccess) -> Void in
            DispatchQueue.main.sync(execute: { () -> Void in
                // user has accepted or not the uses of his camera
                self.cameraAuthorized = alowedAccess
                completion(alowedAccess)
            })
        })

//        AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo, completionHandler: { (alowedAccess) -> Void in
//           // if self.cameraOutputMode == .videoWithMic {
//                AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeAudio, completionHandler: { (alowedAccess) -> Void in
//                    DispatchQueue.main.sync(execute: { () -> Void in
//                        completion(alowedAccess)
//                    })
//                })
//            } else {
//                DispatchQueue.main.sync(execute: { () -> Void in
//                    completion(alowedAccess)
//                })
//                
//            }
//        })
    }

    // Camera session object
    //
    //lazy
    var cameraSession: AVCaptureSession? //{
//        let s = AVCaptureSession()
//        s.sessionPreset = AVCaptureSessionPresetPhoto // AVCaptureSessionPresetHigh //AVCaptureSessionPresetLow
//        return s
//    }()
    

    // Layer to add to an uiview, or ny ui control allowing to display the camera in real time
    //
    //lazy
    public var previewLayer: AVCaptureVideoPreviewLayer?// = {
//        let preview =  AVCaptureVideoPreviewLayer(session: self.cameraSession)
//        // Specify the bounds of the preview component in the view
//        print("preview camera size: " + String(describing: self.previewUIView!.frame.width) + " -- " + String(describing: self.previewUIView!.frame.height))
//        preview?.bounds = CGRect(x: 0, y: 0, width: (self.previewUIView?.frame.width)!, height: (self.previewUIView?.frame.height)!)
//        preview?.anchorPoint = CGPoint(x: 50,y: 0)
//        preview?.position = CGPoint(x: 20, y: 0) //self.view.bounds.midX, y: self.view.bounds.midY)
//        preview?.videoGravity = AVLayerVideoGravityResize //AVLayerVideoGravityResizeAspect //AVLayerVideoGravityResize
//        preview?.frame = CGRect(x: 0, y: 0, width: (self.previewUIView?.frame.width)!, height: (self.previewUIView?.frame.height)!)
//        return preview!
//    }()
    
    
    // setup camera session, without starting to preview the camera
    //
    func setupCameraSession() {
        let captureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo) as AVCaptureDevice
        
        do {
            let deviceInput = try AVCaptureDeviceInput(device: captureDevice)
            
            cameraSession!.beginConfiguration()
            
            if (cameraSession!.canAddInput(deviceInput) == true) {
                cameraSession!.addInput(deviceInput)
            }
            
            let dataOutput = AVCaptureVideoDataOutput()
            dataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(value: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange as UInt32)]
            dataOutput.alwaysDiscardsLateVideoFrames = true
            
            if (cameraSession!.canAddOutput(dataOutput) == true) {
                cameraSession!.addOutput(dataOutput)
            }
            
            cameraSession!.commitConfiguration()
            
            let queue = DispatchQueue(label: "com.invasivecode.videoQueue", attributes: [])
            dataOutput.setSampleBufferDelegate(self, queue: queue)
            
        }
        catch let error as NSError {
            NSLog("\(error), \(error.localizedDescription)")
        }
    }
    
    
    
    
    public func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        // Here you collect each frame and process it
        if (connection.isVideoOrientationSupported){
            //connection.videoOrientation = AVCaptureVideoOrientation.portraitUpsideDown
            connection.videoOrientation = orientation! //AVCaptureVideoOrientation.portrait
        }
        if (connection.isVideoMirroringSupported) {
            //connection.videoMirrored = true
            connection.isVideoMirrored = false
        }
        // call a parent Class, and send the Sample buffer of the camera preview
        delegate?.cameraSessionPreview(sampleBuffer: sampleBuffer)
    }
    
    public func captureOutput(_ captureOutput: AVCaptureOutput!, didDrop sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        // Here you can count how many frames are dopped
    }
    
    
}

