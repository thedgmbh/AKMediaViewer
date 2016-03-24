AKMediaViewer
============

Beautiful iOS library to animate your image and video thumbnails to fullscreen. Written in Swift

[![Build Status](https://travis-ci.org/dogo/AKMediaViewer.svg?branch=master)](https://travis-ci.org/dogo/AKMediaViewer)
[![Cocoapods](http://img.shields.io/cocoapods/v/AKMediaViewer.svg)](http://cocoapods.org/?q=AKMediaViewer-Objective-C)
[![Pod License](http://img.shields.io/cocoapods/l/AKMediaViewer.svg)](https://github.com/dogo/AKMediaViewer/blob/master/LICENSE)

AKMediaViewer gives the ability to focus on any thumbnail image or video by a simple tap. The thumbnail image is automatically animated to a focused fullscreen image view or video player. Another tap on the 'Done' button shrinks (or defocuses) the image back to its initial position.

Each thumbnail image view may have its own transform, the focus and defocus animations take care of any initial transform.

![](https://github.com/autresphere/ASMediaFocusManager/raw/master/Screenshots/video.gif) 

## Video
A video player is shown if the media is a video (supported extension are "mp4" and "mov"). The video player comes with its own controls made of a play/pause button, a slider and time labels. Scrubbing is also available thanks to [ASBPlayerScrubbing](https://github.com/autresphere/ASBPlayerScrubbing).

![](https://github.com/autresphere/AKMediaViewer/raw/master/Screenshots/videoPlayer.jpg) 
![](https://github.com/autresphere/AKMediaViewer/raw/master/Screenshots/videoFocusOnVideo.gif)

## Orientation
The focused view is automatically adapted to the screen orientation even if your main view controller is portrait only.

Because orientation management was different on iOS 5, this class does not work on iOS 5 and below (although it should not be hard to adapt it).

## Image content modes
For now, only `UIViewContentMode.ScaleAspectFit` and `UIViewContentMode.ScaleAspectFill` are supported, but these modes are the most widely used.

In case of `UIViewContentMode.ScaleAspectFill`, the view is expanded in order to show the image in full.

![](https://github.com/autresphere/AKMediaViewer/raw/master/Screenshots/videoAspectFill.gif) 

If you want other content modes to be supported, please drop me a line. You can even try a pull request, which would be much appreciated!

## Image size
When focused, an image is shown fullscreen even if the image is smaller than the screen resolution. In this case no interactive zoom is available.

All Image sizes are supported.

## Exemple Project
See the contained example to get a sample of how `AKMediaViewer` can easily be integrated in your project.

To build the example, you first need to run `pod install` from the `AKMediaViewerExample` directory.

## Installation

AKMediaViewer is available through [CocoaPods](http://cocoapods.org).

To install add the following line to your Podfile:

    pod 'AKMediaViewer'

## Easy to use

* Create a `AKMediaViewerManager`
* Implement its delegate `AKMediaViewerDelegate`.
The delegate returns mainly a media URL, a media title and a parent view controller. 
* Declare all your views that you want to be focusable by calling `.installOnView(view: UIView)`

###Implementing
In your View Controller where some image views need focus feature, add this code.

```swift
override func viewDidLoad() {
    super.viewDidLoad()
    
    mediaFocusManager = AKMediaViewerManager.init()
    mediaFocusManager!.delegate = self

    // Tells which views need to be focusable. You can put your image views in an array and give it to the focus manager.
    mediaFocusManager!.installOnViews(imageViewsArray)
}
```

Here is an example of a delegate implementation. Please adapt the code to your context.
```swift
override func viewDidLoad() {
    ...
    var mediaNames: [String] = ["1f.jpg", "2f.jpg", "3f.mp4", "4f.jpg"]
    ...
}

// MARK: - AKMediaViewerDelegate
// Returns the view controller in which the focus controller is going to be added.
// This can be any view controller, full screen or not.
func parentViewControllerForMediaFocusManager(manager: AKMediaViewerManager) -> UIViewController {
    return self
}

// Returns the URL where the media (image or video) is stored. The URL may be local (file://) or distant (http://).
func mediaFocusManager(manager: AKMediaViewerManager,  mediaURLForView view: UIView) -> NSURL {
    let index: Int = view.tag - 1
    let name: NSString = mediaNames[index]
    let url: NSURL = NSBundle.mainBundle().URLForResource(name.stringByDeletingPathExtension, withExtension: name.pathExtension)!
    
    return url
}

// Returns the title for this media view. Return nil if you don't want any title to appear.
func mediaFocusManager(manager: AKMediaViewerManager, titleForView view: UIView) -> String {
	return "My title"
}

```

If you need to focus or defocus a view programmatically, you can call `startFocusingView` ()as long as the view is focusable) or `endFocusing`.

```swift
mediaFocusManager.startFocusingView(mediaView)
```

###Properties
```swift
public var animationDuration: NSTimeInterval
```
The animation duration. Defaults to 0.5.
```swift
public var backgroundColor: UIColor
```
The background color. Defaults to transparent black.
```swift
public var defocusOnVerticalSwipe: Bool
```
Enables defocus on vertical swipe. Defaults to YES.
```swift
public var elasticAnimation: Bool
```
Returns whether the animation has an elastic effect. Defaults to YES.
```swift
public var zoomEnabled: Bool
```
Returns whether zoom is enabled on fullscreen image. Defaults to YES.
```swift
public var focusOnPinch: Bool
```
Enables focus on pinch gesture. Defaults to False.
```swift
public var gestureDisabledDuringZooming: Bool
```
Returns whether gesture is disabled during zooming. Defaults to YES.
```swift
public var isDefocusingWithTap: Bool
```
Returns whether defocus is enabled with a tap on view. Defaults to NO.
```swift
public var addPlayIconOnVideo: Bool
```
Returns wheter a play icon is automatically added to video thumbnails. Defaults to YES.
```swift
public let playImage: UIImage?
```
Image used to show a play icon on video thumbnails. Defaults to nil (uses internal image).
```swift
public var topAccessoryController: UIViewController?
```
Controller used to show custom accessories. If none is specified a default controller is used with a simple close button.

### Hiding the status bar
On iOS 7, if you want to hide or show the status bar when a view is focused or defocused, you can use optional delegate methods `.mediaFocusManagerWillAppear:` and `.mediaFocusManagerWillDisappear:`.

Here is an example on how to hide and show the status bar. As the delegate methods are called inside an animation block, the status bar will be hidden or shown with animation.
```swift
func mediaFocusManagerWillAppear(manager: AKMediaViewerManager) {
    /*
     *  Call here setDefaultDoneButtonText, if you want to change the text and color of default "Done" button
     *  eg: [self.mediaFocusManager setDefaultDoneButtonText:@"Panda" withColor:[UIColor purpleColor]]
     */
    self.statusBarHidden = true
    if (self.respondsToSelector(#selector(UIViewController.setNeedsStatusBarAppearanceUpdate))) {
        self.setNeedsStatusBarAppearanceUpdate()
    }
}

func mediaFocusManagerWillDisappear(mediaFocusManager: AKMediaViewerManager) {
    self.statusBarHidden = false
    if (self.respondsToSelector(#selector(UIViewController.setNeedsStatusBarAppearanceUpdate))) {
        self.setNeedsStatusBarAppearanceUpdate()
    }
}

override func prefersStatusBarHidden() -> Bool {
    return self.statusBarHidden
}

// statusBarHidden is defined as a property.
var statusBarHidden: Bool = false

```

## Collaboration
I tried to build an easy to use API, while beeing flexible enough for multiple variations, but I'm sure there are ways of improving and adding more features, so feel free to collaborate with ideas, issues and/or pull requests.

## Incoming improvements
- Allow the use of your own video control view.
- Fix image jump on orientation change when fullscreen image is zoomed (only when parent ViewController supports UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown)
- Media browsing by horizontal swipe in fullscreen.

## ARC
AKMediaViewer needs ARC.

## Licence
AKMediaViewer is available under the MIT license.

### Thanks to the original team
Philippe Converset [@autresphere](http://twitter.com/autresphere)

https://github.com/autresphere/ASMediaFocusManager
