//
//  UIVC_CameraScanner_Callback.swift
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

    
    // Note :  the image provided by the camera preview is oriented = up, and have a dimensions like 2000 width x 2666 height.
    // when camera capture the image, it will provide an image oriented = right !, with dimensions like 2666x2000 !
    // take this in account, when manipulating images

    
    // Callback : camera preview content (displayed automatically, not here !)
    //
    // try to detect edges of a document
    //
    func cameraSessionPreview(sampleBuffer: CMSampleBuffer!) {
        DispatchQueue.main.async {
            self.cameraBtn.isEnabled = true
        }
        
        if capturingPhoto { return }
        if computing { return }
        computing = true
        
        var quadrilateral: Quadrilateral?
        let backgroundQueue = DispatchQueue(label: "fr.ormaa.app", qos: .background, target: nil)
        backgroundQueue.sync {
            // detect the edgs of a document in the photo
            quadrilateral = self.edgesDetection?.startDetection(sampleBuffer: sampleBuffer)
        }

        // hide the rectangle of the edges
        drawEdges(pixelBuffer: (self.edgesDetection?.pixelBuffer)!, quadrilateral: quadrilateral!)
        
        // free some system resource.
        // on fast smartphone, there is freeze without that, because calculation is done too many times per seconds.
        usleep(200000) // 200000 = 0.2 sec
    }
    

    
    
    
    
    
    // Delegate 
    // photo captured from Camera
    //
    func pictureCaptured(image: UIImage) {
        print("picture captured, received")

        // Note : the orientation image is = right
        imageCaptured = image
        self.cameraController?.pauseSession()
        
        let backgroundQueue = DispatchQueue(label: "fr.ormaa.app", qos: .background, target: nil)
        backgroundQueue.async {
            // transform + crop the image
            let transform = ImageTransform()
            let temp = transform.DetectCropTransform(image: self.imageCaptured!)
            
            // display it on the screen
            print("smallImage cropped orientation: " + Tools.getOrientation(o: (temp!.imageOrientation)))
            
            DispatchQueue.main.async {
                
                self.smallImage.image = temp
                self.viewSmallImage.isHidden = false
                self.stopWait()
            }
        }
        

    }
    


    
    
    
    // callback
    // from CropAndTransformImageProtocol
    //
    // get an image, transform + crop depending on the edges provided
    //
    func cropAndTransformImage(quadrilateral: Quadrilateral) {
        var temp: UIImage?
        self.startWait()

        print("after edges edit - captured image orientation: " + Tools.getOrientation(o: (imageCaptured!.imageOrientation)))

        let backgroundQueue = DispatchQueue(label: "fr.ormaa.app", qos: .background, target: nil)
        backgroundQueue.async {
            // Crop and transform imageCaptured, with edges updated by user
            let transform = ImageTransform()
            temp = transform.cropAndTransform(image: self.imageCaptured!, quadrilateral: quadrilateral)

            print("after edges edit - cropped orientation: " + Tools.getOrientation(o: (temp!.imageOrientation)))
            
            // set the display document image and small image
            DispatchQueue.main.async {
                // display it on the screen
                self.smallImage.image = temp
                self.viewSmallImage.isHidden = false
                self.stopWait()
            }
        }
        

    }
    
    
    
    

    
    
    
    
    
    
    
    
}
