//
//  SRReader.swift
//  SRReader
//
//  Created by yudai on 2019/1/6.
//  Copyright © 2019 yudai. All rights reserved.
//

import Foundation
import DTCoreText

enum SRReaderScrollType {
    
    /// 仿真翻页 默认
    case curl
    /// 上下滚动
    case vertical
    /// 点击左右切换 无特效
    case none
    /// 左右滑动
    case horizontal
    
}

// MARK: - 属性和生命周期 -
class SRReader: UIViewController {
    
    /// 翻页方式
    private var scrollType = SRReaderScrollType.curl
    
    /// 文本解析器
    private let parser = SRDataParser()
    
    /// 刷新之前最后的章节模型
    private var preModel = SRReaderPage()
    
    /// 仿真翻页控制器
    private lazy var containerVC: UIPageViewController = {
        let cv = UIPageViewController(transitionStyle: .pageCurl, navigationOrientation: .horizontal, options: nil)
        cv.delegate = self
        cv.dataSource = self
        cv.isDoubleSided = true
        return cv
    }()
    
    /// 滑动翻页方式
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.estimatedItemSize = CGSize(width: UIScreen.main.bounds.size.width, height: 200)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        let cv = UICollectionView(frame: UIScreen.main.bounds, collectionViewLayout: layout)
        cv.dataSource = self
        cv.delegate = self
        cv.showsVerticalScrollIndicator = false
        cv.showsHorizontalScrollIndicator = false
        cv.register(SRReaderPageCell.self, forCellWithReuseIdentifier: SRReaderPageCell.reuseIdentifier!)
        cv.backgroundColor = UIColor.white
        cv.scrollsToTop = false
        cv.bounces = false
        if #available(iOS 11.0, *) {
            cv.contentInsetAdjustmentBehavior = .never
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }
        return cv
    }()
    
    /// 刷新标记
    private var isReload = true {
        didSet {
            preModel = parser.modelForItem(at: currentIndexPath)!
        }
    }
    
    /// 当前阅读的页面
    private var currentIndexPath = IndexPath(row: 0, section: 0)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initUI()
        
        initEvent()
        
        let curlBtn = UIButton(type: .contactAdd)
        curlBtn.frame = CGRect(x: 100, y: 100, width: 30, height: 30)
        curlBtn.addTarget(self, action: #selector(changeScrollType(btn:)), for: .touchUpInside)
        curlBtn.tag = 0
        view.addSubview(curlBtn)
        
        let noneBtn = UIButton(type: .contactAdd)
        noneBtn.frame = CGRect(x: 100, y: 150, width: 30, height: 30)
        noneBtn.addTarget(self, action: #selector(changeScrollType(btn:)), for: .touchUpInside)
        noneBtn.tag = 1
        view.addSubview(noneBtn)
        
        let verticalBtn = UIButton(type: .contactAdd)
        verticalBtn.frame = CGRect(x: 100, y: 200, width: 30, height: 30)
        verticalBtn.addTarget(self, action: #selector(changeScrollType(btn:)), for: .touchUpInside)
        verticalBtn.tag = 2
        view.addSubview(verticalBtn)
        
        let horizontalBtn = UIButton(type: .contactAdd)
        horizontalBtn.frame = CGRect(x: 100, y: 250, width: 30, height: 30)
        horizontalBtn.addTarget(self, action: #selector(changeScrollType(btn:)), for: .touchUpInside)
        horizontalBtn.tag = 3
        view.addSubview(horizontalBtn)
        
        let addBtn = UIButton(type: .infoDark)
        addBtn.frame = CGRect(x: 150, y: 100, width: 30, height: 30)
        addBtn.tag = -1
        addBtn.addTarget(self, action: #selector(changeFontSize(btn:)), for: .touchUpInside)
        view.addSubview(addBtn)
        
        let minusBtn = UIButton(type: .infoDark)
        minusBtn.frame = CGRect(x: 150, y: 150, width: 30, height: 30)
        minusBtn.tag = -2
        minusBtn.addTarget(self, action: #selector(changeFontSize(btn:)), for: .touchUpInside)
        view.addSubview(minusBtn)
    }
    
    @objc private func changeFontSize(btn: UIButton) {
        
        isReload = true
        
        if btn.tag == -1 { // 字体放大
            SRReaderConfig.shared.fontSize += 5
        } else {           // 字体缩小
            SRReaderConfig.shared.fontSize -= 5
        }
        
        parser.reloadChapter(in: currentIndexPath.section)
        
    }
    
    private func initUI() {
        parser.acticleName = "单章节7"
    }
    
    private func initEvent() {
        
        parser.chapterUpdatedHandle = { [weak self] chapterIndex, pageModels in
            
            if self?.scrollType != .curl && self?.isReload == false { // 当前是collectionView 需要加载章节cells
                self?.collectionView.reloadSections(IndexSet(arrayLiteral: chapterIndex))
            }
            
            // 是否需要重新刷新界面操作
            // 需要的操作有: 1. 字体大小切换
            if self?.isReload == false { return }
            
            // 获取重分页后的当前页
            let currentPage = self?.parser.locationPageIndex(in: (self?.currentIndexPath.section)!, location: self?.preModel.range?.location ?? 0)
            self?.currentIndexPath = IndexPath(row: currentPage!, section: (self?.currentIndexPath.section)!)
            
            switch self?.scrollType {
            case .curl?:
                self?.setScrollContainer(scrollType: .curl)
                let firstVC = SRReaderPageVC()
                self?.containerVC.setViewControllers([firstVC], direction: .forward, animated: false, completion: nil)
                firstVC.totalPage = (self?.parser.chapterModels[(self?.currentIndexPath.section)!].pageModels.count)!
                firstVC.indexPath = (self?.currentIndexPath)!
                firstVC.dataSource = self?.parser.chapterModels[(self?.currentIndexPath.section)!].pageModels[(self?.currentIndexPath.row)!]
            default:
                self?.collectionView.reloadData()
                self?.collectionView.scrollToItem(at: (self?.currentIndexPath)!, at: .left, animated: false)
            }
            self?.isReload = false
            
        }
        
    }
}

extension SRReader {
    
    /// 变换翻页方式
    @objc private func changeScrollType(btn: UIButton) {
        switch btn.tag {
        case 0: // 仿真翻页
            setScrollContainer(scrollType: .curl)
        case 1: // 上下滑动
            setScrollContainer(scrollType: .vertical)
        case 2: // 点击翻页
            setScrollContainer(scrollType: .none)
        case 3: // 左右滑动
            setScrollContainer(scrollType: .horizontal)
        default:
            break
        }
    }
    
    private func setScrollContainer(scrollType: SRReaderScrollType) {
        guard self.scrollType != scrollType || isReload == true else { return } // 相同选择直接返回
        switch scrollType {
        case .curl:
            collectionView.removeFromSuperview()
            addChild(containerVC)
            view.insertSubview(containerVC.view, at: 0)
            let firstVC = SRReaderPageVC()
            containerVC.setViewControllers([firstVC], direction: .forward, animated: false, completion: nil)
            firstVC.totalPage = parser.chapterModels[currentIndexPath.section].pageModels.count
            firstVC.indexPath = currentIndexPath
            firstVC.dataSource = parser.chapterModels[currentIndexPath.section].pageModels[currentIndexPath.row]
            self.scrollType = .curl
        case .vertical,.horizontal,.none:
            if self.scrollType == .curl { // 控件需要增减
                containerVC.view.removeFromSuperview()
                containerVC.removeFromParent()
                view.insertSubview(collectionView, at: 0)
            }
            collectionView.isScrollEnabled = scrollType == .none ? false : true
            collectionView.isPagingEnabled = scrollType == .vertical ? false : true
            let layout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
            layout.scrollDirection = scrollType == .vertical ? .vertical : .horizontal
            self.scrollType = scrollType
            collectionView.reloadData()
            collectionView.scrollToItem(at: currentIndexPath, at: scrollType == .vertical ? .top : .left, animated: false)
        }
    }
    
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout -
extension SRReader: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollType == .vertical else { return } // 非滚动操作方式可以不用判断
        
        if let cell = collectionView.visibleCells.first {
            let section = collectionView.indexPath(for: cell)?.section
            guard section != currentIndexPath.section else { return }
            // 激活预加载
            parser.currentChapter = section!
        }
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        collectionView.isUserInteractionEnabled = true
        
        if let cell = collectionView.visibleCells.first {
            currentIndexPath = collectionView.indexPath(for: cell)!
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        // 用户滑动停止
        guard scrollType == .vertical else { return }
        if let cell = collectionView.visibleCells.first {
            currentIndexPath = collectionView.indexPath(for: cell)!
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return parser.chapterModels.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return parser.chapterModels[section].pageModels.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SRReaderPageCell.reuseIdentifier!, for: indexPath) as! SRReaderPageCell
        cell.scrollType = scrollType
        cell.totalPage = parser.chapterModels[indexPath.section].pageModels.count
        cell.indexPath = indexPath
        cell.dataSource = parser.chapterModels[indexPath.section].pageModels[indexPath.row]
        cell.tapAction = { [weak self] region in self?.handleTapAction(indexPath: indexPath, tapRegion: region) }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = UIScreen.main.bounds.width
        var height: CGFloat = 0
        if scrollType == .vertical {
            height = parser.chapterModels[indexPath.section].pageModels[indexPath.row].textHeight
        } else {
            height = UIScreen.main.bounds.height
        }
        return CGSize(width: width, height: height)
    }
    
    /// 处理cell的点击事件
    private func handleTapAction(indexPath: IndexPath, tapRegion: SRPageTapRegion) {
        // 是否需要动画
        let needAnima = scrollType == .horizontal ? true : false
        switch tapRegion {
        case .middle:
            print("点击了中间")
        case .left:
            guard scrollType != .vertical else { return }
            if indexPath == IndexPath(row: 0, section: 0) { return }
            collectionView.isUserInteractionEnabled = scrollType == .none ? true : false
            if indexPath.row == 0 { // 切换章节
                collectionView.scrollToItem(at: IndexPath(row: parser.chapterModels[indexPath.section-1].pageModels.count-1, section: indexPath.section-1), at: .left, animated: needAnima)
                currentIndexPath = IndexPath(row: parser.chapterModels[indexPath.section-1].pageModels.count-1, section: indexPath.section-1)
            } else {                // 不用切换章节
                collectionView.scrollToItem(at: IndexPath(row: indexPath.row-1, section: indexPath.section), at: .left, animated: needAnima)
                currentIndexPath = IndexPath(row: indexPath.row-1, section: indexPath.section)
            }
        case .right:
            guard scrollType != .vertical else { return }
            if indexPath.section + 1 == parser.chapterModels.count && indexPath.row + 1 == parser.chapterModels.last?.pageModels.count { return }
            collectionView.isUserInteractionEnabled = scrollType == .none ? true : false
            if indexPath.row+1 == parser.chapterModels[indexPath.section].pageModels.count { // 切换章节
                collectionView.scrollToItem(at: IndexPath(row: 0, section: indexPath.section + 1), at: .left, animated: needAnima)
                currentIndexPath = IndexPath(row: 0, section: indexPath.section + 1)
            } else {                                                                         // 不用切换章节
                collectionView.scrollToItem(at: IndexPath(row: indexPath.row + 1, section: indexPath.section), at: .left, animated: needAnima)
                currentIndexPath = IndexPath(row: indexPath.row + 1, section: indexPath.section)
            }
        }
    }
}

/// 点击页面的区域
public enum SRPageTapRegion {
    case left
    case middle
    case right
}

// MARK: - UIPageViewControllerDelegate, UIPageViewControllerDataSource -
extension SRReader: UIPageViewControllerDelegate, UIPageViewControllerDataSource {
    
    // 1.1 向前翻页
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        
        // 回到全书第一页
        if currentIndexPath == IndexPath(row: 0, section: 0) { return nil }
        
        if viewController is SRReaderPageVC {
            let prePage = SRReaderPageVC()
            if currentIndexPath.row == 0 { // 当前章最后一页
                prePage.totalPage = parser.chapterModels[currentIndexPath.section-1].pageModels.count
                prePage.indexPath = IndexPath(row: currentIndexPath.row-1, section: currentIndexPath.section-1)
                prePage.dataSource = parser.chapterModels[currentIndexPath.section-1].pageModels.last
            } else {
                prePage.totalPage = parser.chapterModels[currentIndexPath.section].pageModels.count
                prePage.indexPath = IndexPath(row: currentIndexPath.row-1, section: currentIndexPath.section)
                prePage.dataSource = parser.chapterModels[currentIndexPath.section].pageModels[currentIndexPath.row-1]
            }
            let backPage = SRReaderPageMirrorVC()
            backPage.mirrorVCView(VC: prePage)
            return backPage
        }
        
        let vc = SRReaderPageVC()
        
        // 未到全书第一页
        if currentIndexPath.row == 0 { // 当前页是章节第一页
            vc.totalPage = parser.chapterModels[currentIndexPath.section-1].pageModels.count
            vc.indexPath = IndexPath(row: parser.chapterModels[currentIndexPath.section-1].pageModels.count-1, section: currentIndexPath.section-1)
            vc.dataSource = parser.chapterModels[currentIndexPath.section-1].pageModels.last
            // 激活预加载
            parser.currentChapter = currentIndexPath.section-1
            //            print("\(currentIndexPath) 向前翻页1")
        } else {                       // 未到章节最后一页
            vc.totalPage = parser.chapterModels[currentIndexPath.section].pageModels.count
            vc.indexPath = IndexPath(row: currentIndexPath.row-1, section: currentIndexPath.section)
            vc.dataSource = parser.chapterModels[currentIndexPath.section].pageModels[currentIndexPath.row-1]
            //            print("\(currentIndexPath) 向前翻页2")
        }
        
        return vc
        
    }
    
    // 1.2 向后翻页
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        
        // 到达全书最后最后一页
        if currentIndexPath.section + 1 == parser.chapterModels.count && currentIndexPath.row + 1 == parser.chapterModels.last?.pageModels.count { return nil }
        
        if viewController is SRReaderPageVC {
            let page = viewController as! SRReaderPageVC
            let backPage = SRReaderPageMirrorVC()
            backPage.mirrorVCView(VC: page)
            return backPage
        }
        
        let vc = SRReaderPageVC()
        // 未到全书最后一页
        if currentIndexPath.row+1 == parser.chapterModels[currentIndexPath.section].pageModels.count { // 当前页是章节最后一页
            vc.totalPage = parser.chapterModels[currentIndexPath.section+1].pageModels.count
            vc.indexPath = IndexPath(row: 0, section: currentIndexPath.section+1)
            vc.dataSource = parser.chapterModels[currentIndexPath.section+1].pageModels.first
            //            print("\(currentIndexPath) 向后翻页1")
            // 激活预加载
            parser.currentChapter = currentIndexPath.section+1
        } else { // 未到章节最后一页
            vc.totalPage = parser.chapterModels[currentIndexPath.section].pageModels.count
            vc.indexPath = IndexPath(row: currentIndexPath.row+1, section: currentIndexPath.section)
            vc.dataSource = parser.chapterModels[currentIndexPath.section].pageModels[currentIndexPath.row+1]
            //            print("\(currentIndexPath) 向后翻页2")
        }
        
        return vc
    }
    
    // 2. 当开始手势转场开始时会被发送。
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
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
        if let textController = pageViewController.viewControllers?.last as? SRReaderPageVC {
            currentIndexPath = textController.indexPath
            //            print("\(currentIndexPath) 结束事件")
        }
        pageViewController.view.isUserInteractionEnabled = true
    }
    
}
