//
//  ViewController.swift
//  AppleSwiftBlurEffect
//
//  Created by Phoenix on 2016/12/19.
//  Copyright © 2016年 Wolkamo. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    @IBAction func valueChange(_ sender: UISlider) {
        let image = UIImage.init(named: "mountains")
        let newImage = image!.applyBlurWithRadius(CGFloat(sender.value), tintColor: UIColor.init(white: 0.2, alpha: 0.1), saturationDeltaFactor: 1.5, maskImage: nil)
        imageView.image = newImage!
    }

}

