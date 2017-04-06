//
//  PageContainerViewController.swift
//  PDFDemo
//
//  Created by qifx on 16/4/12.
//  Copyright © 2016年 qifx. All rights reserved.
//

import UIKit

public struct SourceItem {
    
    public init(id: String, type: String, localUrl: URL?, remoteUrl: URL?, data: Data?) {
        self.id = id
        self.type = type
        self.localUrl = localUrl
        self.remoteUrl = remoteUrl
        self.data = data
    }
    public var id: String
    public var type: String
    public var localUrl: URL?
    public var remoteUrl: URL?
    public var data: Data?
}

public protocol PictureViewerDelegate: class {
    func needDownloadSource(index: Int, item: SourceItem, downloadProgressNotificationName: Notification.Name, downloadEndNotificationName: Notification.Name, downloadErrorNotificationName: Notification.Name)
}

public class PictureViewerController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate, UIGestureRecognizerDelegate, PageChangedDelegate {
        
    //setted data, video URL or UIImage Data
    public var fileDic: Dictionary<Int, SourceItem>
    public var currentFileIndex: Int
    
    public weak var pictureViewerDelegate: PictureViewerDelegate?
    
    /// Init
    ///
    /// - Parameters:
    ///   - fileDic: video URL or UIImage Data
    ///   - currentFileIndex: current file index
    public init(fileDic: Dictionary<Int, SourceItem>, currentFileIndex: Int) {
        self.fileDic = fileDic
        self.currentFileIndex = currentFileIndex
        super.init(transitionStyle: UIPageViewControllerTransitionStyle.scroll, navigationOrientation: UIPageViewControllerNavigationOrientation.horizontal, options: nil)
    }
    
    required public init?(coder: NSCoder) {
        self.fileDic = Dictionary<Int, SourceItem>()
        self.currentFileIndex = 0
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        dataSource = self
        delegate = self
        view.backgroundColor = UIColor.black
        if viewControllers != nil && viewControllers!.count > 0 {
            return
        }
        if let firstViewController = vcAtIndex(currentFileIndex) {
            setViewControllers([firstViewController], direction: .forward, animated: true, completion: nil)
        }
        // Do any additional setup after loading the view.
    }
    
    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: PageChangedDelegate
    func pageChangedTo(index: Int) {
        currentFileIndex = index
    }
    
    //MARK: UIPageViewControllerDataSource
    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        if currentFileIndex == 0 {
            return nil
        }
        return vcAtIndex(currentFileIndex-1)
    }
    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        if currentFileIndex == (fileDic.count - 1) {
            return nil
        }
        return vcAtIndex(currentFileIndex+1)
    }
    
    func vcAtIndex(_ index: Int) -> ContentViewController! {
        let obj = fileDic[index]
        let contentVC = ContentViewController(index: index, si: obj!)
        contentVC.pageChangedDelegate = self
        contentVC.delegate = pictureViewerDelegate
        return contentVC
    }
}
