//
//  SRDataParser.swift
//  SRReader
//
//  Created by yudai on 2019/1/7.
//  Copyright © 2019 yudai. All rights reserved.
//

import Foundation
import DTCoreText

// MARK: - 对外属性方法 -
class SRDataParser {
    
    init() {
        SRReaderConfig.shared.didFontSizeChanged = { size in
            guard let path = Bundle.main.path(forResource: "\(self.acticleName!).txt", ofType: nil) else { return }
            
            self.parseTxtChapter(path: path) { [weak self] strs, models in
                self?.chapterModels = models
                self?.chapterNames = strs
            }
        }
    }
    
    /// 文章名字
    public var acticleName: String? {
        didSet {
            guard let path = Bundle.main.path(forResource: "\(acticleName!).txt", ofType: nil) else { return }

            parseTxtChapter(path: path) { [weak self] strs, models in
                self?.chapterModels = models
                self?.chapterNames = strs
            }
        }
    }
    
    /// 所有章节更新时间回调
    public var chaptersUploadHandle: (() -> Void)?
    
    /// 第一章初始化完成
    public var initializeFirstChapterHandle: (() -> Void)?
    
    /// 所有章节模型
    public var chapterModels = [SRReaderChapter]()
    
    /// 所有章节名数组
    public var chapterNames = [String]()
    
    /// 当前所处章节数 (用于触发预加载下一章)
    public var currentChapter = -1 {
        didSet {
            // 确保是增加章节
            guard oldValue < currentChapter else { return }
            
            // 解析当前章数据
            if chapterModels[currentChapter].pageModels.count == 0 {
                let attriStr = self.attributedString(from: chapterModels[currentChapter])
                
                var pageModels = [SRReaderPage]()
                cutPage(with: attriStr!, config: SRReaderConfig.shared, completeHandler: { [weak self] (int, model, fin) in
                    pageModels.append(model)
                    if fin {
                        self?.chapterModels[currentChapter].pageModels = pageModels.sorted { return $0.pageIndex < $1.pageIndex }
                        if currentChapter == 0 {
                            DispatchQueue.main.async {
                                self?.initializeFirstChapterHandle?()
                            }
                        }
                    }
                })
                
            }
            
            // 解析临近下一章节数据
            // 确保下一章还有
            guard currentChapter+1 < chapterModels.count else { return }
            
            if chapterModels[currentChapter+1].pageModels.count == 0 {
                let nextAttriStr = self.attributedString(from: chapterModels[currentChapter+1])
                
                var nextPageModels = [SRReaderPage]()
                cutPage(with: nextAttriStr!, config: SRReaderConfig.shared, completeHandler: { [weak self] (int, model, fin) in
                    nextPageModels.append(model)
                    if fin {
                        self?.chapterModels[currentChapter+1].pageModels = nextPageModels.sorted { return $0.pageIndex < $1.pageIndex }
                    }
                })
            }
            
        }
        
    }
    
}

// MARK: - 私有方法 -

extension SRDataParser {
    
    /// 解析txt文本文件，分割成单独章节存入沙盒
    ///
    /// - Parameters:
    ///   - path: 文件路径
    ///   - completeHandler: [String]: 章节标题数组
    ///                      [SRChapter]: 文章章节数组
    private func parseTxtChapter(path: String, completeHandler: @escaping ([String], [SRReaderChapter]) -> Void) {
        let url = URL(fileURLWithPath: path)
        // 所有字符串
        let contentStr = try! String(contentsOf: url, encoding: .utf8)
        var titles = [String]()
        
        DispatchQueue.global().async {
            let document = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
            let newPath: NSString = path as NSString
            let fileName = newPath.lastPathComponent.split(separator: ".").first
            let bookPath = document! + "/\(String(fileName!))"
            if FileManager.default.fileExists(atPath: bookPath) == false {
                try? FileManager.default.createDirectory(atPath: bookPath, withIntermediateDirectories: true, attributes: nil)
            }
            
            let results = self.doTitleMatchWith(content: contentStr)
            
            if results.count == 0 { // 一个章节都没有
                let model = SRReaderChapter()
                model.chapterIndex = 1
                model.path = path
                model.title = ""
                completeHandler([], [model])
            } else { // 有一个或多个章节
                
                var endIndex = contentStr.startIndex
                
                for (index, result) in results.enumerated() {
                    // 取出标题相关属性
                    let startIndex = contentStr.index(contentStr.startIndex, offsetBy: result.range.location)
                    endIndex = contentStr.index(startIndex, offsetBy: result.range.length)
                    let currentTitle = String(contentStr[startIndex...endIndex])
                    titles.append(currentTitle)
                    // 创建章节路径
                    let chapterPath = bookPath + "/chapter" + String(index + 1) + ".txt"
                    let chapterModel = SRReaderChapter()
                    chapterModel.chapterIndex = index + 1
                    chapterModel.title = currentTitle
                    chapterModel.path = chapterPath
                    
                    self.chapterModels.append(chapterModel)
                    
                    // 还没有的话创建并写入txt文本
                    if FileManager.default.fileExists(atPath: chapterPath) { continue }
                    var endLoaction = 0
                    if index == results.count - 1 {
                        endLoaction = contentStr.count - 1
                    } else {
                        endLoaction = results[index + 1].range.location - 1
                    }
                    let startLocation = contentStr.index(contentStr.startIndex, offsetBy: result.range.location)
                    let subString = String(contentStr[startLocation...contentStr.index(contentStr.startIndex, offsetBy: endLoaction)])
                    try! subString.write(toFile: chapterPath, atomically: true, encoding: .utf8)
                    
                }
                
                // 只加载第一章的具体数据
                self.currentChapter = 0
                
                DispatchQueue.main.async {
                    completeHandler(titles, self.chapterModels)
                }
            }
        }
    }
    
    /// 把章节模型转化为富文本 (格式化标题 文本)
    ///
    /// - Parameter chapter: 章节模型
    /// - Returns: 章节富文本
    private func attributedString(from chapter: SRReaderChapter) -> NSAttributedString? {
        let tmpUrl = URL(fileURLWithPath: chapter.path!)
        let tmpString = try? String(contentsOf: tmpUrl, encoding: String.Encoding.utf8)
        if tmpString == nil {
            return nil
        }
        let textString: String = tmpString!
        
        let results = self.doTitleMatchWith(content: textString)
        var titleRange = NSRange(location: 0, length: 0)
        if results.count != 0 {
            titleRange = results[0].range
        }
        let startLocation = textString.index(textString.startIndex, offsetBy: titleRange.location)
        let endLocation = textString.index(startLocation, offsetBy: titleRange.length - 1)
        let titleString = String(textString[startLocation...endLocation])
        let contentString = String(textString[textString.index(after: endLocation)...textString.index(before: textString.endIndex)])
        let paraString = self.formatChapterString(contentString: contentString)
        
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
                    NSAttributedString.Key.foregroundColor:UIColor.black]
        
        let newTitle = "\n" + titleString + "\n\n"
        let attrString = NSMutableAttributedString(string: newTitle, attributes: dictTitle)
        let content = NSMutableAttributedString(string: paraString, attributes: dict)
        attrString.append(content)
        
        return attrString
    }
    
    /// 把富文本字符串格式化（设置提行，换行）便于阅读
    ///
    /// - Parameter contentString: 需要格式化的内容
    /// - Returns: 格式化后的内容
    private func formatChapterString(contentString: String) -> String {
        let paragraphArray = contentString.split(separator: "\n")
        var newParagraphString: String = ""
        for (index, paragraph) in paragraphArray.enumerated() {
            let string0 = paragraph.replacingOccurrences(of: " ", with: "")
            let string1 = string0.replacingOccurrences(of: "\t", with: "")
            var newParagraph = string1.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if newParagraph.count != 0 {
                newParagraph = "\t" + newParagraph
                if index != paragraphArray.count - 1 {
                    newParagraph = newParagraph + "\n"
                }
                newParagraphString.append(String(newParagraph))
            }
        }
        return newParagraphString
    }
    
    /// 依据config把富文本切割成pagemodel
    ///
    /// - Parameters:
    ///   - attrString: 需要切割的富文本
    ///   - config: 配置对象
    ///   - completeHandler: 当前页数 模型 完成标志
    private func cutPage(with attrString: NSAttributedString, config: SRReaderConfig, completeHandler: (_ pageCount: Int, _ model: SRReaderPage, _ isCompleted: Bool) -> Void) -> Void {
        
        let layouter = DTCoreTextLayouter(attributedString: attrString)
        let rect = CGRect(x: config.contentFrame.origin.x, y: config.contentFrame.origin.y, width: config.contentFrame.size.width, height: config.contentFrame.size.height - 5)
        var frame = layouter?.layoutFrame(with: rect, range: NSRange(location: 0, length: attrString.length))
        
        var pageVisibleRange = frame?.visibleStringRange()
        var rangeOffset = pageVisibleRange!.location + pageVisibleRange!.length
        var count = 1
        
        while rangeOffset <= attrString.length && rangeOffset != 0 {
            let pageModel = SRReaderPage()
            pageModel.attributedString = attrString.attributedSubstring(from: pageVisibleRange!)
            pageModel.range = pageVisibleRange
            pageModel.pageIndex = count - 1
            
            frame = layouter?.layoutFrame(with: rect, range: NSRange(location: rangeOffset, length: attrString.length - rangeOffset))
            pageVisibleRange = frame?.visibleStringRange()
            if pageVisibleRange == nil {
                rangeOffset = 0
            } else {
                rangeOffset = pageVisibleRange!.location + pageVisibleRange!.length
            }
            
            let completed = (rangeOffset <= attrString.length && rangeOffset != 0) ? false : true
            completeHandler(count, pageModel, completed)
            count += 1
        }
    }
    
    /// 正则判断文章章节方法
    private func doTitleMatchWith(content: String) -> [NSTextCheckingResult] {
        let pattern = "第[ ]*[0-9一二三四五六七八九十百千]*[ ]*[章回].*"
        let regExp = try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let results = regExp.matches(in: content, options: .reportCompletion, range: NSMakeRange(0, content.count))
        return results
    }
}
