//
//  PhotoPicker.swift
//  CameraDocumentScanner
//
//  Created by Olivier Robin - ORMAA - on 16/11/2016.
//  Copyright © 2016 olivier. All rights reserved.
//

import Foundation
import UIKit
import AVKit
import AVFoundation
import Photos

/*
 
 Allow the user to select a photo from local libray, and return it to caller.
 
 Add this to info.plist
 Privacy - Photo Library Usage Description
 
 tag in xml :
 <key>NSPhotoLibraryUsageDescription</key>
 <string>Need to use your libray please</string>
 
 call it using this :
 
 let picker = PhotoPicker()
 picker.pickupPhoto(viewController: self) { (image) -> Void in
 // photo returned
 self.smallImage.image = image
 }
 
 
 */



public class PhotoPicker: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // image picker use when user get photo from library
    let imagePicker = UIImagePickerController()
    
    var viewController: UIViewController?
    
    var pickedImage: UIImage?
    var canceled = false
    
    
    public func hardProcessingWithString(input: String, completion: (_ result: String) -> Void) {
        
        completion("we finished!")
    }
    
    
    public func checkCanGetPhoto() -> Bool {
        
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .authorized:
            return true
        case .denied, .restricted :
            return false
        default:
            return false
            
        }
    }
    
    
    // Get a photo from library
    //
    public func pickupPhoto(viewController: UIViewController, completion:@escaping (_ image: UIImage?) -> Void) {
        
        self.viewController = viewController
        self.pickedImage = nil
        canceled = false
        
        if !checkCanGetPhoto() {
            let ac = UIAlertController(title: "Attention",
                                       message: "Vous n'avez pas autorisé l'accès à votre Librarie photo !\nRendez vous dans le menu \nParamètres, puis\nConfidentialité/Appareil Photo\nAuthorisez Segescan à utiliser votre Caméra", preferredStyle: .alert)
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
            
            viewController.present(ac, animated: true)
            
        }
        
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.photoLibrary) {
            print("pick a photo from library")
            
            // display an image picker, to get a photo from the user library
            //let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerControllerSourceType.photoLibrary;
            imagePicker.allowsEditing = false
            viewController.present(imagePicker, animated: true, completion: nil)
        }
        
        DispatchQueue.global(qos: .background).async {
            print("This is run on the background queue")
            
            // Wait for the file selected and returned in imagePickerController(...)
            repeat {
                //Thread.sleep(forTimeInterval: 500)
                // Sleep for 0.2s
                usleep(200000)
            }
                while self.pickedImage == nil && self.canceled == false
            
            completion(self.pickedImage)
            
            //            DispatchQueue.main.async {
            //                print("This is run on the main queue, after the previous code in outer block")
            //            }
        }
    }
    
    
    
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        canceled = true
        self.viewController?.dismiss(animated: true, completion: nil)
    }
    
    // photo was selected by the user and returned by system
    //
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        print("photo picker delegate called")
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage{
            print("original orientation: " + Tools.getOrientation(o: pickedImage.imageOrientation))
            
            var temp = pickedImage
            
            if (pickedImage.imageOrientation == .up) {
                if pickedImage.size.width < pickedImage.size.height {
                    print("rotate by -90°")
                    
                    // need to turn the image, to have it rendered in portrait
                    // ex. a screen shot, will be .up oriented, and need to be turned by 90°
                    let tools = Tools()
                    let cg = tools.createUIImageDown(imageRef: pickedImage.cgImage)
                    temp = UIImage(cgImage: cg!)
                }
            }
            //            if (pickedImage.imageOrientation == .left) {
            //                if pickedImage.size.width < pickedImage.size.height {
            //                    print("image is left, rotate by 180°")
            //                    let t = ImageTransform()
            //                    //temp = t.Transform(image: pickedImage)!
            //                }
            //            }
            
            print ("image width / height : " + String(describing: pickedImage.size.width) + " / " + String(describing: pickedImage.size.height))
            self.pickedImage = temp //pickedImage
        }
        
        // Remove the image picker allowing to select the photo
        self.viewController?.dismiss(animated: true, completion: nil)
    }
    
    
    
    
    
}
