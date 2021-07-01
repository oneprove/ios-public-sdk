//
//  ViewController.swift
//  DemoClip
//
//  Created by mbpro on 24/07/2021.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    @IBAction func startCameraPressed(_ sender: Any) {
        let vc = TakePhotoViewController()
        vc.delegate = self
        self.present(vc, animated: true, completion: nil)
    }
}

extension ViewController: TakePhotoViewControllerDelegate {
    func didTakeImage(_ image: UIImage) {
        imageView.image = image
        self.dismiss(animated: true, completion: nil)
    }
}

