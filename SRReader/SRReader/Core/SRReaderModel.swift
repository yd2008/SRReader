//
//  SRPageModel.swift
//  SRReader
//
//  Created by yudai on 2019/1/7.
//  Copyright © 2019 yudai. All rights reserved.
//

import UIKit
import DTCoreText

/// 书籍章节模型
class SRReaderChapter {
    
    /// 章节标题
    var title: String?
    /// 章节在沙盒中路径
    var path: String?
    /// 章节序号
    var chapterIndex: Int = 1
    /// 章节对应单页模型
    var pageModels = [SRReaderPage]()
    
}

/// 书籍单页模型
class SRReaderPage {
    
    /// 页面富文本
    var pageAttriStr: NSAttributedString? {
        didSet {
            DispatchQueue.main.async {
                let label = DTAttributedLabel()
                label.attributedString = self.pageAttriStr
                label.frame = CGRect(x: 0, y: 0, width: SRReaderConfig.shared.contentFrame.width, height: 999)
                label.sizeToFit()
                self.textHeight = label.frame.size.height
            }
        }
    }
    /// 页面范围
    var range: NSRange?
    /// 页面在章节中序号
    var pageIndex: Int = 1
    /// 文字高度
    var textHeight: CGFloat = 0.0
    
}


