//
//  SRReaderPageVC.swift
//  SRReader
//
//  Created by yudai on 2019/1/22.
//  Copyright © 2019 yudai. All rights reserved.
//

import UIKit
import DTCoreText

class SRReaderPageVC: UIViewController {
    
    /// 所属章节和页面序号
    public var indexPath = IndexPath(row: 0, section: 0)
    
    /// 当前章节总页数
    public var totalPage = -1
    
    /// 页面模型
    public var dataSource: SRReaderPage? {
        didSet {
            pageLabel.text = "第 \(indexPath.row+1)/\(totalPage) 页"
            attriLabel.attributedString = dataSource?.pageAttriStr
        }
    }
    
    private let attriLabel = DTAttributedLabel(frame: SRReaderConfig.shared.contentFrame)
    
    private let pageLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.black
        view.addSubview(attriLabel)
        attriLabel.backgroundColor = UIColor.brown
        
        pageLabel.frame = CGRect(x: attriLabel.frame.origin.x, y: attriLabel.frame.maxY, width: attriLabel.frame.width, height: UIScreen.main.bounds.height - attriLabel.frame.maxY)
        pageLabel.textAlignment = .right
        pageLabel.font = UIFont.systemFont(ofSize: 12)
        pageLabel.textColor = UIColor.lightGray
        
        view.addSubview(pageLabel)
    }
    
    deinit {
        //        print("TextController deinit -------------")
    }
    
}
