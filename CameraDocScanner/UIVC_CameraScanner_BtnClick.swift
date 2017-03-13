//
//  UIVC_CameraScanner_BtnClick.swift
//  Camera_SCanner_IPDF_Proto
//
//  Created by Olivier Robin on 25/11/2016.
//  Copyright © 2016 Olivier Robin. All rights reserved.
//

import Foundation
import UIKit
import AVKit
import AVFoundation

extension UIVC_CameraScanner {
    
    
    
    
    
    // capture a photo
    //
    @IBAction func capturePhotoBtnClick(_ sender: Any) {
        print("click capture")
        
        if (cameraController?.previewStarted)! {
            
            // hide the preview, disable the preview : free some system resource
            capturingPhoto = true
            cameraPreview.isHidden = true
            edgesView.isHidden = true
            
            startWait()

            let backgroundQueue = DispatchQueue(label: "fr.ormaa.app", qos: .background, target: nil)
            backgroundQueue.async {
                if !(self.cameraController?.capturePhoto())! {
                    // camera could not capture photo
                    DispatchQueue.main.async {
                        let alertController = UIAlertController(title: "Error", message: "Cannot capture photo", preferredStyle: .alert)
                        let OKAction = UIAlertAction(title: "OK", style: .default) { (_) in }
                        alertController.addAction(OKAction)
                        self.present(alertController, animated: true, completion: nil)
                        self.cameraPreview.isHidden = false
                        self.edgesView.isHidden = false
                    }
                }
                else {
                    // photo is captured, callback will be called : func pictureCaptured(image: UIImage)
                }
            }
        }
    }
    

    
    
    // Get a photo from library
    //
    @IBAction func getPhotoBtnClick(_ sender: Any) {
        print(" ")
        print("get photo click")
        
        startWait()
        capturingPhoto = true
        cameraPreview.isHidden = true
        edgesView.isHidden = true
        cameraController?.pauseSession()
        
        // pick a photo from library
        let picker = PhotoPicker()
        picker.pickupPhoto(viewController: self) { (image) -> Void in
            
            if image == nil {
                DispatchQueue.main.async {
                    self.cameraController?.resumeSession()
                    self.capturingPhoto = false
                    self.cameraPreview.isHidden = false
                    self.edgesView.isHidden = false
                    self.viewSmallImage.isHidden = true
                    self.stopWait()
                }
                return
            }
            
            // photo returned in "image"
            
            print("getPhoto orientation: " + Tools.getOrientation(o: image!.imageOrientation))
            
            // Save the captured image locally
            self.imageCaptured = image
            
            var temp: UIImage? = nil
            self.startWait()
            
            let backgroundQueue = DispatchQueue(label: "fr.ormaa.app", qos: .background, target: nil)
            backgroundQueue.async {
                
                // try to detect the document, inside the loaded photo
                // if yes, crop and transform the image (perspective)
                let transform = ImageTransform()
                temp = transform.DetectCropTransform(image: image!)
                print("cropped image orientation: " + Tools.getOrientation(o: temp!.imageOrientation))
                
                if (temp == nil ){
                    print("photo library document : did not found any document edges")
                    let ac = UIAlertController(title: "Error", message: "photo library document : did not found any document edges", preferredStyle: .alert)
                    ac.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(ac, animated: true)
                }

                // set the display document image and small image
                DispatchQueue.main.async {
                    
                    // set the cropped result
                    if temp != nil {
                        self.smallImage.image = temp
                    }
                    else {
                        self.smallImage.image = image
                    }
                    
                    // display the view
                    self.viewSmallImage.isHidden = false
                    self.stopWait()
                }
            }
            

        }
        
    }
    
    
    
    
    
    
    
    
    // Change the flash mode when capture photo
    //
    @IBAction func flashBtnClick(_ sender: Any) {
        
        switch flashMode {
        case .off:
            flashMode = .on
            onOff.text = "on"
        case .on:
            flashMode = .auto
            onOff.text = "auto"
        case .auto:
            flashMode = .off
            onOff.text = "off"
            
        }
        cameraController?.setFlashMode(flashMode: flashMode)
    }
    
    
    
    
    
    
    
    // image transformed + displayed. user click OK
    // Return the image to a caller
    //
    @IBAction func TransformOkBtnClick(_ sender: Any) {
        viewSmallImage.isHidden = true
        self.cameraPreview.isHidden = false
        self.edgesView.isHidden = false
        self.capturingPhoto = false

        cameraController?.resumeSession()
        // Save the image in the parent view controller
        cameraScannerDelegate?.DocumentCaptured(image: self.smallImage.image!)
        
        closeBtnClick(UIButton())
    }
    
    
    
    // user cancel the image captured.
    // display back the camera preview
    @IBAction func transformCancelBtnClick(_ sender: Any) {
        cameraController!.resumeSession()
        viewSmallImage.isHidden = true
        self.cameraPreview.isHidden = false
        self.edgesView.isHidden = false
        self.capturingPhoto = false

    }
    
    
    
    
    
    
    // Edit the Edges
    //
    @IBAction func transformEditBtnClick(_ sender: Any) {
        if imageCaptured == nil { return }
        
        print("click edit edges")
        startWait()
        
        // Stop the camera preview
        cameraController?.pauseSession()
        
        // viewcontroller is associated to a .xib
        //let bundle = Bundle(for: ViewController.self)
        editEdgesPoints = UIVC_EditEdgesPoints(nibName: "UIVC_EditEdgesPoints", bundle: nil) //bundle)
        editEdgesPoints!.delegate = self
        editEdgesPoints!.modalTransitionStyle = UIModalTransitionStyle.crossDissolve

        editEdgesPoints!.image = imageCaptured
        stopWait()
        
        // display the viewController
        present(editEdgesPoints!, animated: true, completion: nil)
    }
    

    
    
    
    // Close btn click : Stop the Camera preview + closethis View
    //
    @IBAction func closeBtnClick(_ sender: Any) {
        cameraController?.stopSession()
        stopWait()
        self.dismiss(animated: true, completion: nil)
    }
    

    
}
