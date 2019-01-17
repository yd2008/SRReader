//
//  ViewController.swift
//  SRReader
//
//  Created by yudai on 2019/1/6.
//  Copyright © 2019 yudai. All rights reserved.
//

import UIKit
import DTCoreText

class ViewController: UIViewController {

    let parser = SRDataParser()
    
    var containerVC: UIPageViewController?
    
    /// 刷新标记
    var isReload = true
    
    /// 当前页
    var currentIndexPath = IndexPath(row: 0, section: 0)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initUI()
        
        initEvent()
        
        let addBtn = UIButton(type: .contactAdd)
        addBtn.frame = CGRect(x: 100, y: 100, width: 100, height: 100)
        addBtn.addTarget(self, action: #selector(addFont), for: .touchUpInside)
        view.addSubview(addBtn)
    }
    
    @objc private func addFont() {
        
        guard let currentPageVC = containerVC?.viewControllers?.last as? TextController else { return }
        
        SRReaderConfig.shared.fontSize += 5
        
        parser.reloadChapter(in: currentIndexPath.section)
        
        isReload = true
        
        // 获取重分页后的当前页
        let currentPage = self.parser.searchPageInChapter(chapter: self.currentIndexPath.section, location: (currentPageVC.dataSource?.range?.location)!)
        self.currentIndexPath = IndexPath(row: currentPage, section: self.currentIndexPath.section)
        
    }
    
    
    
    
    private func initUI() {
        containerVC = UIPageViewController(transitionStyle: .pageCurl, navigationOrientation: .horizontal, options: nil)
        containerVC?.delegate = self
        containerVC?.dataSource = self
        addChild(containerVC!)
        view.addSubview((containerVC?.view)!)
        parser.acticleName = "单章节7"
    }
   
    private func initEvent() {

        parser.chapterUpdatedHandle = { [weak self] chapterIndex in
            if self?.isReload == false { return }
            let firstVC = TextController()
            self?.containerVC?.setViewControllers([firstVC], direction: .forward, animated: false, completion: nil)
            firstVC.totalPage = (self?.parser.chapterModels[(self?.currentIndexPath.section)!].pageModels.count)!
            firstVC.indexPath = (self?.currentIndexPath)!
            firstVC.dataSource = self?.parser.chapterModels[(self?.currentIndexPath.section)!].pageModels[(self?.currentIndexPath.row)!]
            self?.parser.currentChapter = chapterIndex
            self?.isReload = false
        }
        
    }
}

extension ViewController: UIPageViewControllerDelegate, UIPageViewControllerDataSource {
    
    // 1.1 向前翻页
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        
        // 回到全书第一页
        if currentIndexPath == IndexPath(row: 0, section: 0) { return nil }
        
        let vc = TextController()
        
        // 未到全书第一页
        if currentIndexPath.row == 0 { // 当前页是章节第一页
            vc.totalPage = parser.chapterModels[currentIndexPath.section-1].pageModels.count
            vc.indexPath = IndexPath(row: parser.chapterModels[currentIndexPath.section-1].pageModels.count-1, section: currentIndexPath.section-1)
            vc.dataSource = parser.chapterModels[currentIndexPath.section-1].pageModels.last
//            currentIndexPath = vc.indexPath
            // 激活预加载
            parser.currentChapter = currentIndexPath.section-1
            print("\(currentIndexPath) 向前翻页1")
        } else {                       // 未到章节最后一页
            vc.totalPage = parser.chapterModels[currentIndexPath.section].pageModels.count
            vc.indexPath = IndexPath(row: currentIndexPath.row-1, section: currentIndexPath.section)
            vc.dataSource = parser.chapterModels[currentIndexPath.section].pageModels[currentIndexPath.row-1]
//            currentIndexPath = vc.indexPath
            print("\(currentIndexPath) 向前翻页2")
        }
        
        return vc
        
    }
    
    // 1.2 向后翻页
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        
        // 到达全书最后最后一页
        if currentIndexPath.section+1 == parser.chapterModels.count && currentIndexPath.row+1 == parser.chapterModels.last?.pageModels.count { return nil }
        
        let vc = TextController()
        // 未到全书最后一页
        if currentIndexPath.row+1 == parser.chapterModels[currentIndexPath.section].pageModels.count { // 当前页是章节最后一页
            vc.totalPage = parser.chapterModels[currentIndexPath.section+1].pageModels.count
            vc.indexPath = IndexPath(row: 0, section: currentIndexPath.section+1)
            vc.dataSource = parser.chapterModels[currentIndexPath.section+1].pageModels[0]
            print("\(currentIndexPath) 向后翻页1")
//            currentIndexPath = vc.indexPath
            // 激活预加载
            parser.currentChapter = currentIndexPath.section+1
        } else { // 未到章节最后一页
            vc.totalPage = parser.chapterModels[currentIndexPath.section].pageModels.count
            vc.indexPath = IndexPath(row: currentIndexPath.row+1, section: currentIndexPath.section)
            vc.dataSource = parser.chapterModels[currentIndexPath.section].pageModels[currentIndexPath.row+1]
//            currentIndexPath = vc.indexPath
            print("\(currentIndexPath) 向后翻页2")
        }
        
        return vc
    }
    
    // 2. 当开始手势转场开始时会被发送。
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
//        print("即将开始转场")
        pageViewController.view.isUserInteractionEnabled = false
    }
    
    /// 3. 当开始手势转场结束时会被发送。
    ///
    /// - Parameters:
    ///   - pageViewController: 翻页控制器
    ///   - finished: 动画是否完成
    ///   - previousViewControllers: 之前的控制器数组
    ///   - completed:  是否切换了页面
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        
        // 重置当前页码
        if let textController = pageViewController.viewControllers?.last as? TextController {
            currentIndexPath = textController.indexPath
            print("\(currentIndexPath) 结束事件")
        }
        pageViewController.view.isUserInteractionEnabled = true
    }
    
}


class TextController: UIViewController {
    
    /// 所属章节和页面序号
    public var indexPath = IndexPath(row: 0, section: 0)
    
    /// 当前章节总页数
    public var totalPage = -1
    
    /// 页面模型
    public var dataSource: SRReaderPage? {
        didSet {
            pageLabel.text = "第 \(indexPath.row+1)/\(totalPage) 页"
            attriLabel.attributedString = dataSource?.attributedString
        }
    }
    
    private let attriLabel = DTAttributedLabel(frame: SRReaderConfig.shared.contentFrame)
    
    private let pageLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.white
        view.addSubview(attriLabel)
        
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
