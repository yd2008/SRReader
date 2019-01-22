//
//  SRReaderPageMirrorVC.swift
//  SRReader
//
//  Created by yudai on 2019/1/22.
//  Copyright © 2019 yudai. All rights reserved.
//

import UIKit

class SRReaderPageMirrorVC: UIViewController {
    
    var backImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let imageView = UIImageView.init(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height))
        imageView.image = self.backImage
        self.view.addSubview(imageView)
    }
    
    func mirrorVCView(VC: SRReaderPageVC) {
        let rect = VC.view.bounds
        UIGraphicsBeginImageContextWithOptions(rect.size, true, 0.0)
        let context = UIGraphicsGetCurrentContext()
        let transform = CGAffineTransform(a: -1.0, b: 0.0, c: 0.0, d: 1.0, tx: rect.size.width, ty: 0.0)
        context?.concatenate(transform)
        VC.view.layer.render(in: context!)
        self.backImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }
    
}
