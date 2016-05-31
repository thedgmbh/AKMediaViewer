//
//  AKMediaViewerController.swift
//  AKMediaViewer
//
//  Created by Diogo Autilio on 3/18/16.
//  Copyright © 2016 AnyKey Entertainment. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

let kDefaultOrientationAnimationDuration: NSTimeInterval = 0.4
let kDefaultControlMargin: CGFloat = 5

// MARK: - PlayerView

public class PlayerView: UIView {
    
    override public class func layerClass() -> AnyClass {
        return AVPlayerLayer.self
    }
    
    func player() -> AVPlayer {
        return (layer as! AVPlayerLayer).player!
    }
    
    func setPlayer(player: AVPlayer) {
        (layer as! AVPlayerLayer).player = player
    }
}

// MARK: - AKMediaViewerController

public class AKMediaViewerController : UIViewController, UIScrollViewDelegate {
    
    public var tapGesture = UITapGestureRecognizer()
    public var doubleTapGesture = UITapGestureRecognizer()
    public var controlMargin: CGFloat = 0.0
    public var playerView: UIView?
    public var imageScrollView = AKImageScrollView()
    public var controlView: UIView?
    
    @IBOutlet var mainImageView: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var accessoryView: UIView!
    @IBOutlet var contentView: UIView!
    
    var accessoryViewTimer: NSTimer?
    var player: AVPlayer?
    var previousOrientation: UIDeviceOrientation = UIDeviceOrientation.Unknown
    var activityIndicator : UIActivityIndicatorView?
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(AKMediaViewerController.handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        controlMargin = kDefaultControlMargin
        
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(AKMediaViewerController.handleTap(_:)))
        tapGesture.requireGestureRecognizerToFail(doubleTapGesture)
        
        view.addGestureRecognizer(tapGesture)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        if(player != nil) {
            player!.currentItem!.removeObserver(self, forKeyPath: "presentationSize")
        }
        
        mainImageView = nil
        contentView = nil
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.layer.shadowOpacity = 1
        titleLabel.layer.shadowOffset = CGSizeZero
        titleLabel.layer.shadowRadius = 1
        accessoryView.alpha = 0
    }
    
    override public func viewDidAppear(animated: Bool) {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(AKMediaViewerController.orientationDidChangeNotification(_:)), name: UIDeviceOrientationDidChangeNotification, object: nil)
        UIDevice.currentDevice().beginGeneratingDeviceOrientationNotifications()
        super.viewDidAppear(animated)
    }
    
    override public func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIDeviceOrientationDidChangeNotification, object: nil)
        UIDevice.currentDevice().endGeneratingDeviceOrientationNotifications()
    }
    
    override public func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.Portrait
    }
    
    func isParentSupportingInterfaceOrientation(toInterfaceOrientation : UIInterfaceOrientation) -> Bool {
        switch(toInterfaceOrientation)
        {
        case UIInterfaceOrientation.Portrait:
            return parentViewController!.supportedInterfaceOrientations().contains(UIInterfaceOrientationMask.Portrait)
            
        case UIInterfaceOrientation.PortraitUpsideDown:
            return parentViewController!.supportedInterfaceOrientations().contains(UIInterfaceOrientationMask.PortraitUpsideDown)
            
        case UIInterfaceOrientation.LandscapeLeft:
            return parentViewController!.supportedInterfaceOrientations().contains(UIInterfaceOrientationMask.LandscapeLeft)
            
        case UIInterfaceOrientation.LandscapeRight:
            return parentViewController!.supportedInterfaceOrientations().contains(UIInterfaceOrientationMask.LandscapeRight)
            
        case UIInterfaceOrientation.Unknown:
            return true
        }
    }
    
    override public func beginAppearanceTransition(isAppearing: Bool, animated: Bool) {
        if(!isAppearing) {
            accessoryView.alpha = 0
            playerView?.alpha = 0
        }
    }
    
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if(playerView != nil) {
            playerView!.frame = mainImageView.bounds
        }
    }
    
    // MARK: - Public
    
    public func updateOrientationAnimated(animated: Bool) {
        
        var transform: CGAffineTransform?
        var frame: CGRect
        var duration: NSTimeInterval = kDefaultOrientationAnimationDuration
        
        if (UIDevice.currentDevice().orientation == previousOrientation) {
            return
        }
        
        if (UIDeviceOrientationIsLandscape(UIDevice.currentDevice().orientation) && UIDeviceOrientationIsLandscape(previousOrientation)) ||
            (UIDeviceOrientationIsPortrait(UIDevice.currentDevice().orientation) && UIDeviceOrientationIsPortrait(previousOrientation))
        {
            duration *= 2
        }
        
        if(UIDevice.currentDevice().orientation == UIDeviceOrientation.Portrait) || isParentSupportingInterfaceOrientation(UIApplication.sharedApplication().statusBarOrientation) {
            transform = CGAffineTransformIdentity
        } else {
            switch (UIDevice.currentDevice().orientation)
            {
                case UIDeviceOrientation.LandscapeRight:
                    if(parentViewController!.interfaceOrientation == UIInterfaceOrientation.Portrait) {
                        transform = CGAffineTransformMakeRotation(CGFloat(-M_PI_2))
                    } else {
                        transform = CGAffineTransformMakeRotation(CGFloat(M_PI_2))
                    }
                    break
                    
                case UIDeviceOrientation.LandscapeLeft:
                    if(parentViewController!.interfaceOrientation == UIInterfaceOrientation.Portrait) {
                        transform = CGAffineTransformMakeRotation(CGFloat(M_PI_2))
                    } else {
                        transform = CGAffineTransformMakeRotation(CGFloat(-M_PI_2))
                    }
                    break
                    
                case UIDeviceOrientation.Portrait:
                    transform = CGAffineTransformIdentity
                    break
                    
                case UIDeviceOrientation.PortraitUpsideDown:
                    transform = CGAffineTransformMakeRotation(CGFloat(M_PI))
                    break
                    
                case UIDeviceOrientation.FaceDown: return
                case UIDeviceOrientation.FaceUp: return
                case UIDeviceOrientation.Unknown: return
            }
        }
        
        if (animated) {
            frame = contentView.frame
            UIView.animateWithDuration(duration, animations: { () -> Void in
                self.contentView.transform = transform!
                self.contentView.frame = frame
            })
        } else {
            frame = self.contentView.frame
            self.contentView.transform = transform!
            self.contentView.frame = frame
        }
        self.previousOrientation = UIDevice.currentDevice().orientation
    }
    
    public func showPlayerWithURL(url: NSURL) {
        playerView = PlayerView.init(frame: mainImageView.bounds)
        mainImageView.addSubview(self.playerView!)
        playerView!.autoresizingMask = [UIViewAutoresizing.FlexibleWidth , UIViewAutoresizing.FlexibleHeight]
        playerView!.hidden = true
        
        // install loading spinner for remote files
        if(!url.fileURL) {
            self.activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.WhiteLarge)
            self.activityIndicator!.frame = UIScreen.mainScreen().bounds
            self.activityIndicator!.hidesWhenStopped = true
            view.addSubview(self.activityIndicator!)
            self.activityIndicator!.startAnimating()
        }
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.player = AVPlayer(URL: url)
            (self.playerView as! PlayerView).setPlayer(self.player!)
            self.player!.currentItem?.addObserver(self, forKeyPath: "presentationSize", options: NSKeyValueObservingOptions.New, context: nil)
            self.layoutControlView()
            self.activityIndicator?.stopAnimating()
        })
    }
    
    public func focusDidEndWithZoomEnabled(zoomEnabled: Bool) {
        if(zoomEnabled && (playerView == nil)) {
            installZoomView()
        }
        
        view.setNeedsLayout()
        showAccessoryView(true)
        playerView?.hidden = false
        player?.play()
        
        addAccessoryViewTimer()
    }
    
    public func defocusWillStart() {
        if(playerView == nil) {
            uninstallZoomView()
        }
        pinAccessoryView()
        player?.pause()
    }
    
    // MARK: - Private
    
    func addAccessoryViewTimer() {
        if (player != nil) {
            accessoryViewTimer = NSTimer.scheduledTimerWithTimeInterval(1.5, target: self, selector: #selector(AKMediaViewerController.removeAccessoryViewTimer), userInfo: nil, repeats: false)
        }
    }
    
    func removeAccessoryViewTimer() {
        accessoryViewTimer?.invalidate()
        showAccessoryView(false)
    }
    
    func installZoomView() {
        let scrollView: AKImageScrollView = AKImageScrollView.init(frame: contentView.bounds)
        scrollView.autoresizingMask = [UIViewAutoresizing.FlexibleHeight, UIViewAutoresizing.FlexibleWidth]
        scrollView.delegate = self
        imageScrollView = scrollView
        contentView.insertSubview(scrollView, atIndex: 0)
        scrollView.displayImage(mainImageView.image!)
        self.mainImageView.hidden = true
        
        imageScrollView.addGestureRecognizer(doubleTapGesture)
    }
    
    func uninstallZoomView() {
        let frame: CGRect = contentView.convertRect(imageScrollView.zoomImageView!.frame, fromView: imageScrollView)
        imageScrollView.hidden = true
        mainImageView.hidden = false
        mainImageView.frame = frame
    }
    
    func isAccessoryViewPinned() -> Bool {
        return (accessoryView.superview == view)
    }
    
    func pinView(view: UIView) {
        let frame: CGRect = self.view.convertRect(view.frame, fromView: view.superview)
        view.transform = view.superview!.transform
        self.view.addSubview(view)
        view.frame = frame
    }
    
    func pinAccessoryView() {
        // Move the accessory views to the main view in order not to be rotated along with the media.
        pinView(accessoryView)
    }
    
    func showAccessoryView(visible: Bool) {
        if(visible == accessoryViewsVisible()) {
            return
        }
        
        UIView.animateWithDuration(0.5, delay: 0, options: [UIViewAnimationOptions.BeginFromCurrentState, UIViewAnimationOptions.AllowUserInteraction], animations: { () -> Void in
            self.accessoryView.alpha = (visible ? 1 : 0)
            }, completion: nil)
    }
    
    func accessoryViewsVisible() -> Bool {
        return (accessoryView.alpha == 1)
    }
    
    func layoutControlView() {
        var frame: CGRect
        let videoFrame: CGRect
        let titleFrame: CGRect
        
        if(isAccessoryViewPinned()) {
            return
        }
        
        if(self.controlView == nil) {
            let controlView: AKVideoControlView = AKVideoControlView.videoControlView()
            controlView.translatesAutoresizingMaskIntoConstraints = false
            controlView.scrubbing.player = player
            self.controlView = controlView
            accessoryView.addSubview(self.controlView!)
        }
        
        videoFrame = buildVideoFrame()
        frame = self.controlView!.frame
        frame.size.width = self.view.bounds.size.width - self.controlMargin * 2
        frame.origin.x = self.controlMargin
        titleFrame = self.controlView!.superview!.convertRect(titleLabel.frame, fromView: titleLabel.superview)
        frame.origin.y =  titleFrame.origin.y - frame.size.height - self.controlMargin
        if(videoFrame.size.width > 0) {
            frame.origin.y = min(frame.origin.y, CGRectGetMaxY(videoFrame) - frame.size.height - self.controlMargin as CGFloat)
        }
        self.controlView!.frame = frame
        
    }
    
    func buildVideoFrame() -> CGRect {
        if(CGSizeEqualToSize(self.player!.currentItem!.presentationSize, CGSizeZero)) {
            return CGRectZero
        }
        
        var frame: CGRect = AVMakeRectWithAspectRatioInsideRect(self.player!.currentItem!.presentationSize, self.playerView!.bounds)
        frame = CGRectIntegral(frame)
        
        return frame
    }
    
    // MARK: - Actions
    
    func handleTap(gesture: UITapGestureRecognizer) {
        if(imageScrollView.zoomScale == imageScrollView.minimumZoomScale) {
            showAccessoryView(!accessoryViewsVisible())
        }
    }
    
    func handleDoubleTap(gesture: UITapGestureRecognizer) {
        var frame: CGRect = CGRectZero
        var location: CGPoint
        var contentView: UIView
        var scale: CGFloat
        
        if(imageScrollView.zoomScale == imageScrollView.minimumZoomScale) {
            scale = imageScrollView.maximumZoomScale
            contentView = imageScrollView.delegate!.viewForZoomingInScrollView!(imageScrollView)!
            location = gesture.locationInView(contentView)
            frame = CGRectMake(location.x*imageScrollView.maximumZoomScale - imageScrollView.bounds.size.width/2, location.y*imageScrollView.maximumZoomScale - imageScrollView.bounds.size.height/2, imageScrollView.bounds.size.width, imageScrollView.bounds.size.height)
        } else {
            scale = imageScrollView.minimumZoomScale
        }
        
        UIView.animateWithDuration(0.5, delay: 0, options: UIViewAnimationOptions.BeginFromCurrentState, animations: { () -> Void in
            self.imageScrollView.zoomScale = scale
            self.imageScrollView.layoutIfNeeded()
            if (scale == self.imageScrollView.maximumZoomScale) {
                self.imageScrollView.scrollRectToVisible(frame, animated: false)
            }
            }, completion: nil)
    }
    
    // MARK: - <UIScrollViewDelegate>
    
    public func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return imageScrollView.zoomImageView
    }
    
    public func scrollViewDidZoom(scrollView: UIScrollView) {
        showAccessoryView(imageScrollView.zoomScale == imageScrollView.minimumZoomScale)
    }
    
    // MARK: - Notifications
    
    func orientationDidChangeNotification(notification: NSNotification) {
        updateOrientationAnimated(true)
    }
    
    // MARK: - KVO
    override public func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        view.setNeedsLayout()
    }
}
