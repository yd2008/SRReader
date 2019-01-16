//
//  SDReaderConfig.swift
//  SRReader
//
//  Created by yudai on 2019/1/7.
//  Copyright © 2019 yudai. All rights reserved.
//

import UIKit

enum DUAReaderScrollType: Int {
    case curl
    case horizontal
    case vertical
    case none
}

class SRReaderConfig: NSObject {
    
    static let shared = SRReaderConfig()
    
    var contentFrame = CGRect()
    
    var lineHeightMutiplier: CGFloat = 2 {
        didSet {
            self.didLineHeightChanged(lineHeightMutiplier)
        }
    }
    
    var fontSize: CGFloat = 25 {
        didSet {
            self.didFontSizeChanged(fontSize)
        }
    }
    
    var fontName:String! {
        didSet {
            self.didFontNameChanged(fontName)
        }
    }
    
    var backgroundImage:UIImage! {
        didSet {
            self.didBackgroundImageChanged(backgroundImage)
        }
    }
    
    var scrollType = DUAReaderScrollType.curl {
        didSet {
            self.didScrollTypeChanged(scrollType)
        }
    }
    
    var didFontSizeChanged: (CGFloat) -> Void = { _ in }
    var didFontNameChanged: (String) -> Void = { _ in }
    var didBackgroundImageChanged: (UIImage) -> Void = { _ in }
    var didLineHeightChanged: (CGFloat) -> Void = { _ in }
    var didScrollTypeChanged: (DUAReaderScrollType) -> Void = {_ in }
    
    private override init() {
        super.init()
        let font = UIFont.systemFont(ofSize: self.fontSize)
        self.fontName = font.fontName
        let safeAreaTopHeight: CGFloat = UIScreen.main.bounds.size.height == 812.0 ? 24 : 0
        let safeAreaBottomHeight: CGFloat = UIScreen.main.bounds.size.height == 812.0 ? 34 : 0
        self.contentFrame = CGRect(x: 30, y: 30 + safeAreaTopHeight, width: UIScreen.main.bounds.size.width - 60, height: UIScreen.main.bounds.size.height - 60.0 - safeAreaTopHeight - safeAreaBottomHeight)
    }
    
}
