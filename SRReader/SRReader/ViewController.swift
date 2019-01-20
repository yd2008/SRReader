//
//  ViewController.swift
//  SRReader
//
//  Created by yudai on 2019/1/6.
//  Copyright © 2019 yudai. All rights reserved.
//

import UIKit
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

class ViewController: UIViewController {
    
    /// 翻页方式
    private var scrollType = SRReaderScrollType.vertical

    /// 文本解析器
    private let parser = SRDataParser()
    
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
        if #available(iOS 11.0, *) {
            cv.contentInsetAdjustmentBehavior = .never
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }
        return cv
    }()
    
    /// 刷新标记
    private var isReload = true
    
    /// 当前阅读的页面
    private var currentIndexPath = IndexPath(row: 0, section: 0)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initUI()
        
        initEvent()
        
        let curlBtn = UIButton(type: .contactAdd)
        curlBtn.frame = CGRect(x: 100, y: 100, width: 100, height: 50)
        curlBtn.addTarget(self, action: #selector(changeScrollType(btn:)), for: .touchUpInside)
        curlBtn.tag = 0
        view.addSubview(curlBtn)
        
        let noneBtn = UIButton(type: .contactAdd)
        noneBtn.frame = CGRect(x: 100, y: 150, width: 100, height: 50)
        noneBtn.addTarget(self, action: #selector(changeScrollType(btn:)), for: .touchUpInside)
        noneBtn.tag = 1
        view.addSubview(noneBtn)
        
        let verticalBtn = UIButton(type: .contactAdd)
        verticalBtn.frame = CGRect(x: 100, y: 200, width: 100, height: 50)
        verticalBtn.addTarget(self, action: #selector(changeScrollType(btn:)), for: .touchUpInside)
        verticalBtn.tag = 2
        view.addSubview(verticalBtn)
        
        let horizontalBtn = UIButton(type: .contactAdd)
        horizontalBtn.frame = CGRect(x: 100, y: 250, width: 100, height: 50)
        horizontalBtn.addTarget(self, action: #selector(changeScrollType(btn:)), for: .touchUpInside)
        horizontalBtn.tag = 3
        view.addSubview(horizontalBtn)
        
        let addBtn = UIButton(type: .contactAdd)
        addBtn.frame = CGRect(x: 100, y: 300, width: 100, height: 50)
        addBtn.addTarget(self, action: #selector(addFont), for: .touchUpInside)
//        addBtn.tag = 3
        view.addSubview(addBtn)
    }
    
    @objc private func addFont() {
        
//        guard let currentPageVC = containerVC?.viewControllers?.last as? TextController else { return }
//
//        SRReaderConfig.shared.fontSize += 5
//
//        parser.reloadChapter(in: currentIndexPath.section)
//
//        isReload = true
//
//        // 获取重分页后的当前页
//        let currentPage = self.parser.searchPageInChapter(chapter: self.currentIndexPath.section, location: (currentPageVC.dataSource?.range?.location)!)
//        self.currentIndexPath = IndexPath(row: currentPage, section: self.currentIndexPath.section)
        
        collectionView.reloadSections(IndexSet(arrayLiteral: 1))
        
    }
    
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
        guard self.scrollType != scrollType else { return } // 相同选择直接返回
        switch scrollType {
        case .curl:
            collectionView.removeFromSuperview()
            addChild(containerVC)
            view.insertSubview(containerVC.view, at: 0)
            let firstVC = TextController()
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
        }
        
    }
    
    private func initUI() {

        parser.acticleName = "单章节7"
    }
   
    private func initEvent() {

        parser.chapterUpdatedHandle = { [weak self] chapterIndex in
            if self?.isReload == false { return }
            self?.setScrollContainer(scrollType: .curl)
            switch self?.scrollType {
            case .curl?:
                let firstVC = TextController()
                self?.containerVC.setViewControllers([firstVC], direction: .forward, animated: false, completion: nil)
                firstVC.totalPage = (self?.parser.chapterModels[(self?.currentIndexPath.section)!].pageModels.count)!
                firstVC.indexPath = (self?.currentIndexPath)!
                firstVC.dataSource = self?.parser.chapterModels[(self?.currentIndexPath.section)!].pageModels[(self?.currentIndexPath.row)!]
                self?.parser.currentChapter = chapterIndex
            case .vertical?:
                self?.collectionView.reloadData()
            default:
                break
            }
            self?.isReload = false
        }
        
    }
}

extension ViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
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
    
}

class SRReaderPageCell: UICollectionViewCell {
    
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
            } else {
                attriLabel.frame = SRReaderConfig.shared.contentFrame
                pageLabel.frame = CGRect(x: attriLabel.frame.origin.x, y: attriLabel.frame.maxY, width: attriLabel.frame.width, height: UIScreen.main.bounds.height - attriLabel.frame.maxY)
                pageLabel.text = "第 \(indexPath.row+1)/\(totalPage) 页"
                contentView.addSubview(pageLabel)
            }
        }
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
    
    public static var reuseIdentifier: String? {
        return "SRReaderPageCell"
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = UIColor.black
        contentView.addSubview(attriLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        contentView.backgroundColor = UIColor.black
        contentView.addSubview(attriLabel)
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


class DUABackViewController: UIViewController {
    
    var backImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let imageView = UIImageView.init(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height))
        imageView.image = self.backImage
        self.view.addSubview(imageView)
    }
    
    func mirrorVCView(VC: TextController) {
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

extension ViewController: UIPageViewControllerDelegate, UIPageViewControllerDataSource {
    
    // 1.1 向前翻页
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        
        // 回到全书第一页
        if currentIndexPath == IndexPath(row: 0, section: 0) { return nil }
        
        if viewController is TextController {
            let prePage = TextController()
            if currentIndexPath.row == 0 { // 当前章最后一页
                prePage.totalPage = parser.chapterModels[currentIndexPath.section-1].pageModels.count
                prePage.indexPath = IndexPath(row: currentIndexPath.row-1, section: currentIndexPath.section-1)
                prePage.dataSource = parser.chapterModels[currentIndexPath.section-1].pageModels.last
            } else {
                prePage.totalPage = parser.chapterModels[currentIndexPath.section].pageModels.count
                prePage.indexPath = IndexPath(row: currentIndexPath.row-1, section: currentIndexPath.section)
                prePage.dataSource = parser.chapterModels[currentIndexPath.section].pageModels[currentIndexPath.row-1]
            }
            let backPage = DUABackViewController()
            backPage.mirrorVCView(VC: prePage)
            return backPage
        }
        
        let vc = TextController()
        
        // 未到全书第一页
        if currentIndexPath.row == 0 { // 当前页是章节第一页
            vc.totalPage = parser.chapterModels[currentIndexPath.section-1].pageModels.count
            vc.indexPath = IndexPath(row: parser.chapterModels[currentIndexPath.section-1].pageModels.count-1, section: currentIndexPath.section-1)
            vc.dataSource = parser.chapterModels[currentIndexPath.section-1].pageModels.last
            // 激活预加载
            parser.currentChapter = currentIndexPath.section-1
            print("\(currentIndexPath) 向前翻页1")
        } else {                       // 未到章节最后一页
            vc.totalPage = parser.chapterModels[currentIndexPath.section].pageModels.count
            vc.indexPath = IndexPath(row: currentIndexPath.row-1, section: currentIndexPath.section)
            vc.dataSource = parser.chapterModels[currentIndexPath.section].pageModels[currentIndexPath.row-1]
            print("\(currentIndexPath) 向前翻页2")
        }
        
        return vc
        
    }
    
    // 1.2 向后翻页
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        
        // 到达全书最后最后一页
        if currentIndexPath.section + 1 == parser.chapterModels.count && currentIndexPath.row + 1 == parser.chapterModels.last?.pageModels.count { return nil }
        
        if viewController is TextController {
            let page = viewController as! TextController
            let backPage = DUABackViewController()
            backPage.mirrorVCView(VC: page)
            return backPage
        }
        
        let vc = TextController()
        // 未到全书最后一页
        if currentIndexPath.row + 1 == parser.chapterModels[currentIndexPath.section].pageModels.count { // 当前页是章节最后一页
            vc.totalPage = parser.chapterModels[currentIndexPath.section+1].pageModels.count
            vc.indexPath = IndexPath(row: 0, section: currentIndexPath.section+1)
            vc.dataSource = parser.chapterModels[currentIndexPath.section+1].pageModels.first
            print("\(currentIndexPath) 向后翻页1")
            // 激活预加载
            parser.currentChapter = currentIndexPath.section+1
        } else { // 未到章节最后一页
            vc.totalPage = parser.chapterModels[currentIndexPath.section].pageModels.count
            vc.indexPath = IndexPath(row: currentIndexPath.row+1, section: currentIndexPath.section)
            vc.dataSource = parser.chapterModels[currentIndexPath.section].pageModels[currentIndexPath.row+1]
            print("\(currentIndexPath) 向后翻页2")
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
        if let textController = pageViewController.viewControllers?.last as? TextController {
            currentIndexPath = textController.indexPath
            print("\(currentIndexPath) 结束事件")
        }
        pageViewController.view.isUserInteractionEnabled = true
    }
    
}
