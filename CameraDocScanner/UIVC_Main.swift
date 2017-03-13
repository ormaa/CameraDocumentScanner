//
//  MainViewController.swift
//  CameraDocumentScanner
//
//  Created by Olivier Robin on 16/11/2016.
//  Copyright © 2016 olivier. All rights reserved.
//

import UIKit

class UIVC_Main: UIViewController, CameraScannerProtocol {

    @IBOutlet weak var image: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func startScanner(_ sender: Any) {
        
        //let myVC = UIVC_CameraScannerIPDF(nibName: "UIVC_CameraScannerIPDF", bundle: nil)
        //myVC.modalTransitionStyle = UIModalTransitionStyle.flipHorizontal

        let myVC = UIVC_CameraScanner(nibName: "UIVC_CameraScanner", bundle: nil)
        myVC.modalTransitionStyle = UIModalTransitionStyle.flipHorizontal
        myVC.cameraScannerDelegate = self
        
        
        present(myVC, animated: true, completion: nil)
    }

    internal func DocumentCaptured(image: UIImage) {
        self.image.image = image
        let tools = Tools()
        tools.savePhotoToLibrary(image: image, uiViewController: self)
    }
}
