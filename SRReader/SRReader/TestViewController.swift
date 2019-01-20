//
//  TestViewController.swift
//  SRReader
//
//  Created by yudai on 2019/1/18.
//  Copyright © 2019 yudai. All rights reserved.
//

import UIKit
import DTCoreText

class TestViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let title = "第一章"
        
        let content = "阿斯加德播放框架喇叭首付款阿什顿发士大夫；收到感受到个； 阿适； 搭嘎收到；个阿适；低功耗拉十多个会热火估价师个"
        
        let paragraphStyleTitle = NSMutableParagraphStyle()
        paragraphStyleTitle.alignment = NSTextAlignment.center
        let dictTitle = [NSAttributedString.Key.font:UIFont.boldSystemFont(ofSize: 19),
                         NSAttributedString.Key.paragraphStyle:paragraphStyleTitle]
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = NSTextAlignment.justified
        paragraphStyle.lineHeightMultiple = SRReaderConfig.shared.lineHeightMutiplier
        let font = UIFont(name: SRReaderConfig.shared.fontName, size: SRReaderConfig.shared.fontSize)
        let dict = [NSAttributedString.Key.font:font!,
                    NSAttributedString.Key.paragraphStyle:paragraphStyle,
                    NSAttributedString.Key.foregroundColor:UIColor.white]
        
        let newTitle = "\n" + title + "\n\n"
        let attrString = NSMutableAttributedString(string: newTitle, attributes: dictTitle)
        let finStr = NSMutableAttributedString(string: content, attributes: dict)
        attrString.append(finStr)
        
        let label = DTAttributedLabel()
        label.attributedString = attrString
//        label.frame.origin = CGPoint.zero
        label.frame = CGRect(x: 0, y: 0, width: 375, height: 999)
        label.sizeToFit()
        label.backgroundColor = UIColor.clear
        print(label.frame)
        
        view.addSubview(label)
    }
    

  

}
