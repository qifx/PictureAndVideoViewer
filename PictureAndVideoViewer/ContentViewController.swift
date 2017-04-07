//
//  PageViewController.swift
//  PDFDemo
//
//  Created by qifx on 16/4/12.
//  Copyright © 2016年 qifx. All rights reserved.
//

import UIKit
import AVFoundation

protocol PageChangedDelegate: NSObjectProtocol {
    func pageChangedTo(index: Int)
}

public class ContentViewController: UIViewController, UIScrollViewDelegate {

    //setted data
    var index: Int
    public var si: SourceItem
    weak var delegate: PictureViewerDelegate?
    
    
    var scrollView: UIScrollView!
    var mainView: UIView!
    
    
    var iv: UIImageView?
    var downloadingView: UIView?
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer!
    
    weak var pageChangedDelegate: PageChangedDelegate?
    
    var showButtons: Bool = false

    init(index: Int, si: SourceItem) {
        self.index = index
        self.si = si
        super.init(nibName: nil, bundle: nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black
        if scrollView == nil {
            scrollView = UIScrollView(frame: view.bounds)
            scrollView.delegate = self
            scrollView.scrollsToTop = false
            scrollView.contentSize = CGSize(width: view.bounds.width, height: view.bounds.height)
            scrollView.bounces = true
            scrollView.bouncesZoom = true
            scrollView.isPagingEnabled = true
            scrollView.isScrollEnabled = false
            scrollView.showsVerticalScrollIndicator = false
            scrollView.showsHorizontalScrollIndicator = false
            scrollView.isDirectionalLockEnabled = true
            scrollView.minimumZoomScale = 1.0
            scrollView.maximumZoomScale = 2.0
            scrollView.zoomScale = 1.0
            scrollView.backgroundColor = UIColor.black
            view.addSubview(scrollView)
        }
        // Do any additional setup after loading the view.
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if mainView == nil {
            mainView = UIView(frame: scrollView.bounds)
            mainView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.tapped(gesture:))))
            mainView.center = scrollView.center
            scrollView.addSubview(mainView)
        }
            if si.data != nil {
                //show picture
                iv = UIImageView(frame: scrollView.bounds)
                iv!.contentMode = .scaleAspectFit
                iv!.image = UIImage(data: si.data!)
                mainView.addSubview(iv!)
            } else if si.localUrl != nil {
                player = AVPlayer(url: si.localUrl!)
                playerLayer = AVPlayerLayer(player: player)
                playerLayer.frame = mainView.bounds
                playerLayer.videoGravity = AVLayerVideoGravityResizeAspect
                mainView.layer.addSublayer(playerLayer)
            } else {
                downloadingView = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
                downloadingView!.center = CGPoint(x: scrollView.center.x, y: scrollView.center.y)
                downloadingView!.backgroundColor = UIColor.black
                mainView.addSubview(downloadingView!)
                let progress = KDCircularProgress(frame: downloadingView!.bounds)
                progress.startAngle = -90
                progress.progressThickness = 0.2
                progress.trackThickness = 0.3
                progress.clockwise = true
                progress.gradientRotateSpeed = 2
                progress.roundedCorners = true
                progress.glowMode = .forward
                progress.glowAmount = 0.9
                progress.set(colors: UIColor.white)
                progress.tag = 10086
                downloadingView!.addSubview(progress)
            }
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        pageChangedDelegate?.pageChangedTo(index: index)
        if iv == nil && player == nil {
            let progressName = Notification.Name.init(rawValue: "DownloadVideoProgress\(si.id)")
            let endName = Notification.Name.init(rawValue: "DownloadVideoEnd\(si.id)")
            let errorName = Notification.Name.init(rawValue: "DownloadVideoError\(si.id)")
            NotificationCenter.default.addObserver(self, selector: #selector(self.updatePercent(noti:)), name: progressName, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(self.downloadEnd), name: endName, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(self.downloadError), name: errorName, object: nil)
            delegate?.needDownloadSource(index: index, item: si, downloadProgressNotificationName: progressName, downloadEndNotificationName: endName, downloadErrorNotificationName: errorName)
        } else if player != nil {
            self.downloadingView?.removeFromSuperview()
            self.downloadingView = nil
            player?.play()
        }
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        player?.pause()
    }
    
    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tapped(gesture: UITapGestureRecognizer) {
        dismiss(animated: true, completion: nil)
    }
    
    func updatePercent(noti: Notification) {
        guard let percent = noti.userInfo?["percent"] as? Double, let progressView = downloadingView?.viewWithTag(10086) as? KDCircularProgress else {
            return
        }
        progressView.progress = percent
    }
    
    func downloadEnd() {
        self.downloadingView?.removeFromSuperview()
        self.downloadingView = nil
        self.player = AVPlayer(url: self.si.localUrl!)
        self.playerLayer = AVPlayerLayer(player: self.player)
        self.playerLayer.frame = self.mainView.bounds
        self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect
        self.mainView.layer.addSublayer(self.playerLayer)
        self.player!.play()
    }
    
    func downloadError() {
        let ac = UIAlertController(title: "Download end with error", message: "Can not download video from \(si.remoteUrl!)", preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        ac.addAction(ok)
        present(ac, animated: true, completion: nil)
    }
    
    //UIScrollViewDelegate
    public func viewForZooming(in scrollView: UIScrollView) -> UIView?  {
        if si.data != nil {
            return mainView
        } else {
            return nil
        }
    }
    
    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        var centerX = scrollView.center.x
        var centerY = scrollView.center.y
        centerX = scrollView.contentSize.width > scrollView.frame.size.width ? scrollView.contentSize.width * 0.5 : centerX
        centerY = scrollView.contentSize.height > scrollView.frame.size.height ? scrollView.contentSize.height * 0.5 : centerY
        mainView.center = CGPoint(x: centerX, y: centerY)
    }
}
