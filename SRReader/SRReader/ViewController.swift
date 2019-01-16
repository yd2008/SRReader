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
    
    var containerVC: SRContainerPageVC?
    
    var pageVC = TextController()
    
    /// 当前章节
    var currentChapter = 1
    
    /// 当前页码
    var currentPage = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        containerVC = SRContainerPageVC(transitionStyle: .pageCurl, navigationOrientation: .horizontal, options: nil)
        containerVC?.delegate = self
        containerVC?.dataSource = self
        addChild(containerVC!)
        view.addSubview((containerVC?.view)!)
        
        containerVC?.setViewControllers([pageVC], direction: .forward, animated: true, completion: nil)
        
        parser.acticleName = "郭黄之恋"
        
        DispatchQueue.main.asyncAfter(deadline: .now()+1) {
            self.pageVC.dataSource = self.parser.chapterModels[self.currentChapter-1].pageModels?.first
            self.pageVC.chapterIndex = 0
            self.pageVC.pageIndex = 0
        }
        
    }
    
 

   
}

extension ViewController: UIPageViewControllerDelegate, UIPageViewControllerDataSource {
    
    ///1.1 向前翻页事件触发
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        let vc = TextController()
        currentPage -= 1
        vc.dataSource = parser.chapterModels[currentChapter].pageModels?[currentPage]
        return vc
    }
    
    ///1.2 向后翻页事件触发
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        let vc = TextController()
        currentPage += 1
//        print(currentPage)
//        print("\(parser.chapterModels[currentChapter].pageModels?.count)  ----------")
        if currentPage == (parser.chapterModels[currentChapter-1].pageModels?.count)!+1 { // 当前章节最后一页
            currentPage = 0
            currentChapter += 1
            vc.pageIndex = currentPage
            vc.chapterIndex = currentChapter
        } else { // 还没有到最后一页
            vc.pageIndex = currentPage
            vc.chapterIndex = currentChapter
        }
        
        
        vc.dataSource = parser.chapterModels[currentChapter-1].pageModels?[currentPage]
//        print(parser.chapterModels)
        // 获取下一章模型
        return vc
    }
    
    //2. 当开始手势转场开始时会被发送。
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
//        print("即将开始转场")
    }
    
    //3. 当开始手势转场结束时会被发送。
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
//        print("转场完成")
        
        // 重置当前
        print(previousViewControllers.count)
    }
    
}

class SRContainerPageVC: UIPageViewController {
    var willStepIntoNextChapter = false
    var willStepIntoLastChapter = false
}

class TextController: UIViewController {
    
    /// 页面所属章节
    var chapterIndex = -1
    
    /// 所属页面序号
    var pageIndex = -1
    
    let attriLabel = DTAttributedLabel(frame: SRReaderConfig.shared.contentFrame)
    
    var dataSource: SRReaderPage? {
        didSet {
            attriLabel.attributedString = dataSource?.attributedString
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.white
        view.addSubview(attriLabel)
    }
    
    deinit {
//        print("TextController deinit -------------")
    }
    
}
