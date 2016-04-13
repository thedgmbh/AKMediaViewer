//
//  AKMediaViewerManager.swift
//  AKMediaViewer
//
//  Created by Diogo Autilio on 3/18/16.
//  Copyright © 2016 AnyKey Entertainment. All rights reserved.
//

import Foundation
import UIKit

let kAnimateElasticSizeRatio: CGFloat = 0.03
let kAnimateElasticDurationRatio: Double = 0.6
let kAnimateElasticSecondMoveSizeRatio: CGFloat = 0.5
let kAnimateElasticThirdMoveSizeRatio: CGFloat = 0.2
let kAnimationDuration: Double = 0.5
let kSwipeOffset: CGFloat = 100

// MARK: - <AKMediaViewerDelegate>

@objc public protocol AKMediaViewerDelegate : NSObjectProtocol {
    // Returns the view controller in which the focus controller is going to be added. This can be any view controller, full screen or not.
    func parentViewControllerForMediaFocusManager(manager: AKMediaViewerManager) -> UIViewController
    
    // Returns the URL where the media (image or video) is stored. The URL may be local (file://) or distant (http://).
    func mediaFocusManager(manager: AKMediaViewerManager, mediaURLForView view: UIView) -> NSURL
    
    // Returns the title for this media view. Return nil if you don't want any title to appear.
    func mediaFocusManager(manager: AKMediaViewerManager, titleForView view: UIView) -> String
    
    // MARK: - <AKMediaViewerDelegate> Optional
    
    /*
     Returns an image view that represents the media view. This image from this view is used in the focusing animation view.
     It is usually a small image. If not implemented, default is the initial media view in case it's an UIImageview.
    */
    optional func mediaFocusManager(manager: AKMediaViewerManager, imageViewForView view: UIView) -> UIImageView
    
    // Returns the final focused frame for this media view. This frame is usually a full screen frame. If not implemented, default is the parent view controller's view frame.
    optional func mediaFocusManager(manager: AKMediaViewerManager, finalFrameForView view: UIView) -> CGRect
    
    // Called when a focus view is about to be shown. For example, you might use this method to hide the status bar.
    optional func mediaFocusManagerWillAppear(manager: AKMediaViewerManager)
    
    // Called when a focus view has been shown.
    optional func mediaFocusManagerDidAppear(manager: AKMediaViewerManager)
    
    // Called when the view is about to be dismissed by the 'done' button or by gesture. For example, you might use this method to show the status bar (if it was hidden before).
    optional func mediaFocusManagerWillDisappear(manager: AKMediaViewerManager)
    
    // Called when the view has be dismissed by the 'done' button or by gesture.
    optional func mediaFocusManagerDidDisappear(manager: AKMediaViewerManager)
    
    // Called before mediaURLForView to check if image is already on memory.
    optional func mediaFocusManager(manager: AKMediaViewerManager, cachedImageForView view: UIView) -> UIImage
}

// MARK: - AKMediaViewerManager

public class AKMediaViewerManager : NSObject, UIGestureRecognizerDelegate {
    
    // The animation duration. Defaults to 0.5.
    public var animationDuration: NSTimeInterval
    
    // The background color. Defaults to transparent black.
    public var backgroundColor: UIColor
    
    // Enables defocus on vertical swipe. Defaults to True.
    public var defocusOnVerticalSwipe: Bool
    
    // Returns whether the animation has an elastic effect. Defaults to True.
    public var elasticAnimation: Bool
    
    // Returns whether zoom is enabled on fullscreen image. Defaults to True.
    public var zoomEnabled: Bool
    
    // Enables focus on pinch gesture. Defaults to False.
    public var focusOnPinch: Bool
    
    // Returns whether gesture is disabled during zooming. Defaults to True.
    public var gestureDisabledDuringZooming: Bool
    
    // Returns whether defocus is enabled with a tap on view. Defaults to False.
    public var isDefocusingWithTap: Bool
    
    // Returns wheter a play icon is automatically added to media view which corresponding URL is of video type. Defaults to True.
    public var addPlayIconOnVideo: Bool
    
    // Controller used to show custom accessories. If none is specified a default controller is used with a simple close button.
    public var topAccessoryController: UIViewController?
    
    // Image used to show a play icon on video thumbnails. Defaults to nil (uses internal image).
    public let playImage: UIImage?
    
    public var delegate: AKMediaViewerDelegate?
    
    // The media view being focused.
    var mediaView = UIView()
    var focusViewController: AKMediaViewerController?
    var isZooming: Bool
    var videoBehavior: AKVideoBehavior
    
    override init() {
        
        animationDuration = kAnimationDuration
        backgroundColor = UIColor.init(white: 0.0, alpha: 0.8)
        defocusOnVerticalSwipe = true
        elasticAnimation = true
        zoomEnabled = true
        isZooming = false
        focusOnPinch = false
        gestureDisabledDuringZooming = true
        isDefocusingWithTap = false
        addPlayIconOnVideo = true
        videoBehavior = AKVideoBehavior()
        playImage = UIImage()
        super.init()
    }
    
    // Install focusing gesture on the specified array of views.
    public func installOnViews(views: NSArray) {
        for view in views {
            installOnView(view as! UIView)
        }
    }
    
    // Install focusing gesture on the specified view.
    public func installOnView(view: UIView) {
        let tapGesture: UITapGestureRecognizer = UITapGestureRecognizer.init(target: self, action: #selector(AKMediaViewerManager.handleFocusGesture(_:)))
        view.addGestureRecognizer(tapGesture)
        view.userInteractionEnabled = true
        
        let pinchRecognizer: UIPinchGestureRecognizer = UIPinchGestureRecognizer.init(target: self, action: #selector(AKMediaViewerManager.handlePinchFocusGesture(_:)))
        pinchRecognizer.delegate = self
        view.addGestureRecognizer(pinchRecognizer)
        
        let url: NSURL = delegate!.mediaFocusManager(self, mediaURLForView: view)
        if(addPlayIconOnVideo && isVideoURL(url)) {
            videoBehavior.addVideoIconToView(view, image: playImage)
        }
    }
    
    func installDefocusActionOnFocusViewController(focusViewController: AKMediaViewerController!) {
        // We need the view to be loaded.
        if(focusViewController.view != nil) {
            if(isDefocusingWithTap) {
                let tapGesture: UITapGestureRecognizer = UITapGestureRecognizer.init(target: self, action: #selector(AKMediaViewerManager.handleDefocusGesture(_:)))
                tapGesture.requireGestureRecognizerToFail(focusViewController.doubleTapGesture)
                focusViewController.view.addGestureRecognizer(tapGesture)
            } else {
                setupAccessoryViewOnFocusViewController(focusViewController)
            }
        }
    }
    
    func setupAccessoryViewOnFocusViewController(focusViewController: AKMediaViewerController!) {
        if(topAccessoryController == nil) {
            let defaultController: AKMediaFocusBasicToolbarController = AKMediaFocusBasicToolbarController(nibName: "AKMediaFocusBasicToolbar", bundle: nil)
            defaultController.view.backgroundColor = UIColor.clearColor()
            defaultController.doneButton.addTarget(self, action: #selector(AKMediaViewerManager.endFocusing), forControlEvents:UIControlEvents.TouchUpInside)
            topAccessoryController = defaultController
        }
        
        var frame: CGRect = topAccessoryController!.view.frame
        frame.size.width = focusViewController.accessoryView.frame.size.width
        topAccessoryController!.view.frame = frame
        focusViewController.accessoryView.addSubview(topAccessoryController!.view)
    }
    
    // MARK: - Utilities
    
    // Taken from https://github.com/rs/SDWebImage/blob/master/SDWebImage/SDWebImageDecoder.m
    func decodedImageWithImage(image: UIImage) -> UIImage {
        // do not decode animated images
        if ((image.images) != nil) {
            return image
        }
        
        let imageRef: CGImageRef = image.CGImage!
        
        let alpha: CGImageAlphaInfo = CGImageGetAlphaInfo(imageRef)
        let anyAlpha: Bool = (alpha == CGImageAlphaInfo.First ||
            alpha == CGImageAlphaInfo.Last ||
            alpha == CGImageAlphaInfo.PremultipliedFirst ||
            alpha == CGImageAlphaInfo.PremultipliedLast)
        
        if (anyAlpha) {
            return image
        }
        
        // current
        let imageColorSpaceModel: CGColorSpaceModel = CGColorSpaceGetModel(CGImageGetColorSpace(imageRef))
        var colorspaceRef: CGColorSpaceRef = CGImageGetColorSpace(imageRef)!
        
        let unsupportedColorSpace: Bool = (imageColorSpaceModel == CGColorSpaceModel.Unknown ||
                                            imageColorSpaceModel == CGColorSpaceModel.Monochrome ||
                                            imageColorSpaceModel == CGColorSpaceModel.CMYK ||
                                            imageColorSpaceModel == CGColorSpaceModel.Indexed)
        
        if (unsupportedColorSpace) {
            colorspaceRef = CGColorSpaceCreateDeviceRGB()!
        }
        
        let width: size_t = CGImageGetWidth(imageRef)
        let height: size_t = CGImageGetHeight(imageRef)
        let bytesPerPixel: Int = 4
        let bytesPerRow: Int = bytesPerPixel * width
        let bitsPerComponent: Int = 8
        
        // CGImageAlphaInfo.None is not supported in CGBitmapContextCreate.
        // Since the original image here has no alpha info, use CGImageAlphaInfo.NoneSkipLast
        // to create bitmap graphics contexts without alpha info.
        let context: CGContextRef = CGBitmapContextCreate(nil,
            width,
            height,
            bitsPerComponent,
            bytesPerRow,
            colorspaceRef,
            CGBitmapInfo.ByteOrderDefault.rawValue | CGImageAlphaInfo.NoneSkipLast.rawValue)!
        
        // Draw the image into the context and retrieve the new bitmap image without alpha
        CGContextDrawImage(context, CGRectMake(0, 0, CGFloat(width), CGFloat(height)), imageRef)
        let imageRefWithoutAlpha: CGImageRef = CGBitmapContextCreateImage(context)!
        let imageWithoutAlpha: UIImage = UIImage.init(CGImage: imageRefWithoutAlpha, scale: image.scale, orientation: image.imageOrientation)
        
        return imageWithoutAlpha
    }
    
    func rectInsetsForRect(frame: CGRect, withRatio ratio: CGFloat) -> CGRect {
        let dx: CGFloat
        let dy: CGFloat
        var resultFrame: CGRect
        
        dx = frame.size.width * ratio
        dy = frame.size.height * ratio
        resultFrame = CGRectInset(frame, dx, dy)
        resultFrame = CGRectMake(round(resultFrame.origin.x), round(resultFrame.origin.y), round(resultFrame.size.width), round(resultFrame.size.height))
        
        return resultFrame
    }
    
    func sizeThatFitsInSize(boundingSize: CGSize, initialSize size: CGSize)  -> CGSize {
        // Compute the final size that fits in boundingSize in order to keep aspect ratio from initialSize.
        let fittingSize: CGSize
        let widthRatio: CGFloat
        let heightRatio: CGFloat
        
        widthRatio = boundingSize.width / size.width
        heightRatio = boundingSize.height / size.height
        
        if (widthRatio < heightRatio) {
            fittingSize = CGSizeMake(boundingSize.width, floor(size.height * widthRatio))
        } else {
            fittingSize = CGSizeMake(floor(size.width * heightRatio), boundingSize.height)
        }
        
        return fittingSize
    }
    
    func focusViewControllerForView(mediaView: UIView) -> AKMediaViewerController? {
        
        let viewController: AKMediaViewerController
        let image: UIImage?
        var imageView: UIImageView?
        let url: NSURL?
        
        imageView = delegate?.mediaFocusManager?(self, imageViewForView: mediaView)
        
        if (imageView == nil && mediaView.isKindOfClass(UIImageView)) {
            imageView = mediaView as? UIImageView
        }
        
        image = imageView!.image
        if((imageView == nil) || (image == nil)) {
            return nil
        }
        
        url = delegate?.mediaFocusManager(self, mediaURLForView: mediaView)
        if(url == nil) {
            print("Warning: url is nil")
            return nil
        }
        
        viewController = AKMediaViewerController.init(nibName: "AKMediaViewerController", bundle: nil)
        installDefocusActionOnFocusViewController(viewController)
        
        viewController.titleLabel.text = delegate?.mediaFocusManager(self, titleForView: mediaView)
        viewController.mainImageView.image = image
        viewController.mainImageView.contentMode = imageView!.contentMode
        
        let cachedImage: UIImage? = delegate?.mediaFocusManager?(self, cachedImageForView: mediaView)
        if (cachedImage != nil) {
            viewController.mainImageView.image = cachedImage
            return viewController
        }
        
        if (isVideoURL(url!)) {
            viewController.showPlayerWithURL(url!)
        } else {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                self.loadImageFromURL(url!, onImageView: viewController.mainImageView)
            })
        }
        return viewController
    }
    
    func loadImageFromURL(url: NSURL, onImageView imageView: UIImageView) {
        let data: NSData
        
        do {
            try data = NSData.init(contentsOfURL: url, options: NSDataReadingOptions.DataReadingMappedAlways)
            
            var image: UIImage = UIImage.init(data: data)!
            image = decodedImageWithImage(image)
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                imageView.image = image
            })
        } catch {
            print("Warning: Unable to load image at %@. %@", url, error)
        }
    }
    
    func isVideoURL(url: NSURL) -> Bool {
        let fileExtension: String = url.pathExtension!.lowercaseString
        return (fileExtension == "mp4" || fileExtension == "mov")
    }
    
    // MARK: - Focus/Defocus
    
    // Start the focus animation on the specified view. The focusing gesture must have been installed on this view.
    public func startFocusingView(mediaView: UIView) {
        
        let parentViewController: UIViewController
        let focusViewController: AKMediaViewerController?
        let center: CGPoint
        let imageView: UIImageView
        let duration: NSTimeInterval
        var finalImageFrame: CGRect?
        var untransformedFinalImageFrame: CGRect = CGRectZero
        
        focusViewController = focusViewControllerForView(mediaView)!
        
        if(focusViewController == nil) {
            return
        }
        
        self.focusViewController = focusViewController!
        
        if(self.defocusOnVerticalSwipe) {
            installSwipeGestureOnFocusView()
        }
        
        // This should be called after swipe gesture is installed to make sure the nav bar doesn't hide before animation begins.
        delegate?.mediaFocusManagerWillAppear?(self)
        
        self.mediaView = mediaView
        parentViewController = (delegate?.parentViewControllerForMediaFocusManager(self))!
        parentViewController.addChildViewController(focusViewController!)
        parentViewController.view.addSubview(focusViewController!.view)
        
        focusViewController!.view.frame = parentViewController.view.bounds
        mediaView.hidden = true
        
        imageView = focusViewController!.mainImageView
        center = (imageView.superview?.convertPoint(mediaView.center, fromView: mediaView.superview))!
        imageView.center = center
        imageView.transform = mediaView.transform
        imageView.bounds = mediaView.bounds
        imageView.layer.cornerRadius = mediaView.layer.cornerRadius
        
        self.isZooming = true
        
        finalImageFrame = self.delegate?.mediaFocusManager?(self, finalFrameForView: mediaView)
        if (finalImageFrame == nil) {
            finalImageFrame = parentViewController.view.bounds
        }
        
        if(imageView.contentMode == UIViewContentMode.ScaleAspectFill) {
            let size: CGSize = sizeThatFitsInSize(finalImageFrame!.size, initialSize: imageView.image!.size)
            finalImageFrame!.size = size
            finalImageFrame!.origin.x = (focusViewController!.view.bounds.size.width - size.width) / 2
            finalImageFrame!.origin.y = (focusViewController!.view.bounds.size.height - size.height) / 2
        }
        
        UIView .animateWithDuration(self.animationDuration) { () -> Void in
            focusViewController!.view.backgroundColor = self.backgroundColor
            focusViewController?.beginAppearanceTransition(true, animated: true)
        }
        
        duration = (elasticAnimation ? animationDuration * (1.0 - kAnimateElasticDurationRatio) : self.animationDuration)
        
        UIView.animateWithDuration(self.animationDuration,
            animations: { () -> Void in
                var frame: CGRect
                let initialFrame: CGRect
                let initialTransform: CGAffineTransform
                
                frame = finalImageFrame!
                
                // Trick to keep the right animation on the image frame.
                // The image frame shoud animate from its current frame to a final frame.
                // The final frame is computed by taking care of a possible rotation regarding the current device orientation, done by calling updateOrientationAnimated.
                // As this method changes the image frame, it also replaces the current animation on the image view, which is not wanted.
                // Thus to recreate the right animation, the image frame is set back to its inital frame then to its final frame.
                // This very last frame operation recreates the right frame animation.
                initialTransform = imageView.transform
                imageView.transform = CGAffineTransformIdentity
                initialFrame = imageView.frame
                imageView.frame = frame
                focusViewController!.updateOrientationAnimated(false)
                // This is the final image frame. No transform.
                untransformedFinalImageFrame = imageView.frame
                frame =  self.elasticAnimation ? self.rectInsetsForRect(untransformedFinalImageFrame, withRatio: -kAnimateElasticSizeRatio) : untransformedFinalImageFrame
                // It must now be animated from its initial frame and transform.
                imageView.frame = initialFrame
                imageView.transform = initialTransform
                imageView.layer .removeAllAnimations()
                imageView.transform = CGAffineTransformIdentity
                imageView.frame = frame
                
                if (mediaView.layer.cornerRadius > 0) {
                    self.animateCornerRadiusOfView(imageView, withDuration: duration, from: Float(mediaView.layer.cornerRadius), to: 0.0)
                }
            }, completion: { (finished: Bool) -> Void in
                UIView.animateWithDuration(self.elasticAnimation ? self.animationDuration * (kAnimateElasticDurationRatio / 3.0) : 0.0,
                    animations: { () -> Void in
                        var frame: CGRect = untransformedFinalImageFrame
                        frame = (self.elasticAnimation ? self.rectInsetsForRect(frame, withRatio:kAnimateElasticSizeRatio * kAnimateElasticSecondMoveSizeRatio) : frame)
                        imageView.frame = frame
                    }, completion: { (finished: Bool) -> Void in
                        UIView.animateWithDuration(self.elasticAnimation ? self.animationDuration * (kAnimateElasticDurationRatio / 3.0) : 0.0,
                            animations: { () -> Void in
                                var frame: CGRect = untransformedFinalImageFrame
                                frame = (self.elasticAnimation ? self.rectInsetsForRect(frame, withRatio: -kAnimateElasticSizeRatio * kAnimateElasticThirdMoveSizeRatio) : frame)
                                imageView.frame = frame
                            }, completion: { (finished: Bool) -> Void in
                                UIView.animateWithDuration(self.elasticAnimation ? self.animationDuration * (kAnimateElasticDurationRatio / 3.0) : 0.0,
                                    animations: { () -> Void in
                                        imageView.frame = untransformedFinalImageFrame
                                    }, completion: { (finished: Bool) -> Void in
                                        self.focusViewController!.focusDidEndWithZoomEnabled(self.zoomEnabled)
                                        self.isZooming = false
                                        self.delegate?.mediaFocusManagerDidAppear?(self)
                                })
                        })
                })
        })
    }
    
    func animateCornerRadiusOfView(view: UIView, withDuration duration: NSTimeInterval, from initialValue: Float, to finalValue: Float) {
        let animation: CABasicAnimation = CABasicAnimation.init(keyPath: "cornerRadius")
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        animation.fromValue = initialValue
        animation.toValue = finalValue
        animation.duration = duration
        view.layer.cornerRadius = CGFloat(finalValue)
        view.layer.addAnimation(animation, forKey: "cornerRadius")
    }
    
    func updateAnimatedView(view: UIView?, fromFrame initialFrame: CGRect?, toFrame finalFrame: CGRect) {
        // On iOS8 previous animations are not replaced when a new one is defined with the same key.
        // Instead the new animation is added a number suffix on its key.
        // To prevent from having additive animations, previous animations are removed.
        // Note: We don't want to remove all animations as there might be some opacity animation that must remain.
        view?.layer.removeAnimationForKey("bounds.size")
        view?.layer.removeAnimationForKey("bounds.origin")
        view?.layer.removeAnimationForKey("position")
        view?.frame = initialFrame!
        view?.layer.removeAnimationForKey("bounds.size")
        view?.layer.removeAnimationForKey("bounds.origin")
        view?.layer.removeAnimationForKey("position")
        view?.frame = finalFrame
    }
    
    func updateBoundsDuringAnimationWithElasticRatio(ratio: CGFloat) {
        var initialFrame: CGRect? = CGRectZero
        var frame: CGRect = mediaView.bounds
        
        initialFrame = focusViewController!.playerView?.frame
        frame = (elasticAnimation ? rectInsetsForRect(frame, withRatio: ratio) : frame)
        focusViewController!.mainImageView.bounds = frame
        updateAnimatedView(focusViewController!.playerView, fromFrame: initialFrame, toFrame: frame)
    }
    
    // Start the close animation on the current focused view.
    public func endFocusing() {
        let duration: NSTimeInterval
        let contentView: UIView
        
        if(isZooming && gestureDisabledDuringZooming) {
            return
        }
        
        focusViewController!.defocusWillStart()
        
        contentView = self.focusViewController!.mainImageView
        
        UIView.animateWithDuration(self.animationDuration) { () -> Void in
            self.focusViewController!.view.backgroundColor = UIColor.clearColor()
        }
        
        UIView.animateWithDuration(self.animationDuration / 2) { () -> Void in
            self.focusViewController!.beginAppearanceTransition(false, animated: true)
        }
        
        duration = (self.elasticAnimation ? self.animationDuration * (1.0 - kAnimateElasticDurationRatio) : self.animationDuration)
        
        if (self.mediaView.layer.cornerRadius > 0) {
            animateCornerRadiusOfView(contentView, withDuration: duration, from: 0.0, to: Float(self.mediaView.layer.cornerRadius))
        }
        
        UIView.animateWithDuration(duration,
            animations: { () -> Void in
                self.delegate?.mediaFocusManagerWillDisappear?(self)
                self.focusViewController!.contentView.transform = CGAffineTransformIdentity
                contentView.center = contentView.superview!.convertPoint(self.mediaView.center, fromView: self.mediaView.superview)
                contentView.transform = self.mediaView.transform
                self.updateBoundsDuringAnimationWithElasticRatio(kAnimateElasticSizeRatio)
            }, completion: { (finished: Bool) -> Void in
                UIView.animateWithDuration(self.elasticAnimation ? self.animationDuration * (kAnimateElasticDurationRatio / 3.0) : 0.0,
                    animations: { () -> Void in
                        self.updateBoundsDuringAnimationWithElasticRatio(-kAnimateElasticSizeRatio * kAnimateElasticSecondMoveSizeRatio)
                    }, completion: { (finished: Bool) -> Void in
                        UIView.animateWithDuration(self.elasticAnimation ? self.animationDuration * (kAnimateElasticDurationRatio / 3.0) : 0.0,
                            animations: { () -> Void in
                                self.updateBoundsDuringAnimationWithElasticRatio(kAnimateElasticSizeRatio * kAnimateElasticThirdMoveSizeRatio)
                            }, completion: { (finished: Bool) -> Void in
                                UIView.animateWithDuration(self.elasticAnimation ? self.animationDuration * (kAnimateElasticDurationRatio / 3.0) : 0.0,
                                    animations: { () -> Void in
                                        self.updateBoundsDuringAnimationWithElasticRatio(0.0)
                                    }, completion: { (finished: Bool) -> Void in
                                        self.mediaView.hidden = false
                                        self.focusViewController!.view .removeFromSuperview()
                                        self.focusViewController!.removeFromParentViewController()
                                        self.focusViewController = nil
                                        self.delegate?.mediaFocusManagerDidDisappear?(self)
                                })
                        })
                })
        })
    }
    
    
    // MARK: - Gestures
    
    func handlePinchFocusGesture(gesture: UIPinchGestureRecognizer) {
        if (gesture.state == UIGestureRecognizerState.Began && !isZooming && gesture.scale > 1) {
            startFocusingView(gesture.view!)
        }
    }
    
    func handleFocusGesture(gesture: UIGestureRecognizer) {
        startFocusingView(gesture.view!)
    }
    
    func handleDefocusGesture(gesture: UIGestureRecognizer) {
        endFocusing()
    }
    
    public func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        if (gestureRecognizer.isKindOfClass(UIPinchGestureRecognizer)) {
            return focusOnPinch
        }
        return true
    }
    
    // MARK: - Dismiss on swipe
    func installSwipeGestureOnFocusView() {
        
        var swipeGesture: UISwipeGestureRecognizer = UISwipeGestureRecognizer.init(target: self, action: #selector(AKMediaViewerManager.handleDefocusBySwipeGesture(_:)))
        swipeGesture.direction = UISwipeGestureRecognizerDirection.Up
        focusViewController!.view.addGestureRecognizer(swipeGesture)
        
        swipeGesture = UISwipeGestureRecognizer.init(target: self, action: #selector(AKMediaViewerManager.handleDefocusBySwipeGesture(_:)))
        swipeGesture.direction = UISwipeGestureRecognizerDirection.Down
        focusViewController!.view.addGestureRecognizer(swipeGesture)
        focusViewController!.view.userInteractionEnabled = true
    }
    
    func handleDefocusBySwipeGesture(gesture: UISwipeGestureRecognizer) {
        let contentView: UIView
        let offset: CGFloat
        let duration: NSTimeInterval = self.animationDuration
        
        focusViewController!.defocusWillStart()
        offset = (gesture.direction == UISwipeGestureRecognizerDirection.Up ? -kSwipeOffset : kSwipeOffset)
        contentView = focusViewController!.mainImageView
        
        UIView.animateWithDuration(duration) {
            self.focusViewController!.view.backgroundColor = UIColor.clearColor()
        }
        
        UIView.animateWithDuration(duration / 2) {
            self.focusViewController!.beginAppearanceTransition(false, animated: true)
        }
        
        UIView.animateWithDuration(0.4 * duration,
                                   animations: {
                                    self.delegate?.mediaFocusManagerWillDisappear?(self)
                                    self.focusViewController!.contentView.transform = CGAffineTransformIdentity
                                    
                                    contentView.center = CGPointMake(self.focusViewController!.view.center.x, self.focusViewController!.view.center.y + offset)
                                    }, completion: { (finished: Bool) -> Void in
                                        UIView.animateWithDuration(0.6 * duration,
                                            animations: {
                                                contentView.center = contentView.superview!.convertPoint(self.mediaView.center, fromView: self.mediaView.superview)
                                                contentView.transform = self.mediaView.transform
                                                self.updateBoundsDuringAnimationWithElasticRatio(0)
                                            }, completion: { (finished: Bool) -> Void in
                                                self.mediaView.hidden = false
                                                self.focusViewController!.view.removeFromSuperview()
                                                self.focusViewController!.removeFromParentViewController()
                                                self.focusViewController = nil
                                                self.delegate?.mediaFocusManagerDidDisappear?(self)
                                                })
                                        })
    }
    
    // MARK: - Customization
    
    // Set minimal customization to default "Done" button. (Text and Color)
    public func setDefaultDoneButtonText(text: String, withColor color: UIColor) {
        (topAccessoryController as! AKMediaFocusBasicToolbarController).doneButton.setTitle(text, forState: UIControlState.Normal)
        (topAccessoryController as! AKMediaFocusBasicToolbarController).doneButton.setTitleColor(color, forState: UIControlState.Normal)
    }
}