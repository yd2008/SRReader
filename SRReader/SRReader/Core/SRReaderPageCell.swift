//
//  SRReaderPageCell.swift
//  SRReader
//
//  Created by yudai on 2019/1/22.
//  Copyright © 2019 yudai. All rights reserved.
//

import UIKit
import DTCoreText

class SRReaderPageCell: UICollectionViewCell {
    
    /// 点击事件
    public var tapAction: ((_ tapRegion: SRPageTapRegion) -> Void)?
    
    /// 当前滚动方式
    public var scrollType: SRReaderScrollType = .curl
    
    /// 所属章节和页面序号
    public var indexPath = IndexPath(row: 0, section: 0)
    
    /// 当前章节总页数
    public var totalPage = 999
    
    /// 页面模型
    public var dataSource: SRReaderPage? {
        didSet {
            attriLabel.attributedString = dataSource?.pageAttriStr
            if scrollType == .vertical { // 不需要页脚
                pageLabel.removeFromSuperview()
                attriLabel.frame = CGRect(x: 30, y: 0, width: UIScreen.main.bounds.width - 60, height: (dataSource?.textHeight)!)
            } else {                     // 需要页脚
                attriLabel.frame = SRReaderConfig.shared.contentFrame
                pageLabel.frame = CGRect(x: attriLabel.frame.origin.x, y: attriLabel.frame.maxY, width: attriLabel.frame.width, height: UIScreen.main.bounds.height - attriLabel.frame.maxY)
                pageLabel.text = "第 \(indexPath.row+1)/\(totalPage) 页"
                contentView.addSubview(pageLabel)
            }
        }
    }
    
    /// 重用标识
    public static var reuseIdentifier: String? {
        return "SRReaderPageCell"
    }
    
    /// 富文本标签
    private lazy var attriLabel: DTAttributedLabel = {
        let al = DTAttributedLabel()
        al.backgroundColor = UIColor.brown
        return al
    }()
    
    /// 页脚标签
    private lazy var pageLabel: UILabel = {
        let pl = UILabel()
        pl.textAlignment = .right
        pl.font = UIFont.systemFont(ofSize: 12)
        pl.textColor = UIColor.lightGray
        return pl
    }()
    
    /// 点击事件
    private lazy var tapGesture: UITapGestureRecognizer = {
        let tg = UITapGestureRecognizer(target: self, action: #selector(tapAction(ges:)))
        return tg
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initUI()
    }
    
    private func initUI() {
        contentView.backgroundColor = UIColor.black
        contentView.addSubview(attriLabel)
        contentView.addGestureRecognizer(tapGesture)
    }
    
    @objc private func tapAction(ges: UITapGestureRecognizer) {
        let location = ges.location(in: self)
        let trisectionWidth = contentView.frame.size.width / 3
        switch location.x {
        case 0..<trisectionWidth                      : tapAction?(.left)
        case trisectionWidth..<trisectionWidth * 2    : tapAction?(.middle)
        case trisectionWidth * 2...trisectionWidth * 3: tapAction?(.right)
        default: break
        }
    }
    
    
}
