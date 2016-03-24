Pod::Spec.new do |spec|
  spec.name         = "AKMediaViewer"
  spec.version      = "0.0.1"
  spec.summary      = "Beautiful iOS library to animate your image and video thumbnails to fullscreen. Written in Swift"
  spec.homepage     = "https://github.com/dogo/AKMediaViewer"
  spec.screenshots  = "https://raw.githubusercontent.com/dogo/AKMediaViewer/master/ScreenShots/ScreenShot.png", "https://raw.githubusercontent.com/dogo/AKMediaViewer/master/ScreenShots/ScreenShot2.png"

  spec.license            		= { :type => "MIT", :file => "LICENSE" }
  spec.author             		= { "Diogo Autilio" => "diautilio@gmail.com" }
  spec.social_media_url   		= "http://twitter.com/di_autilio"
  spec.platform           		= :ios
  spec.frameworks             = "UIKit", "Foundation", "CoreGraphics", "AVFoundation"
  spec.ios.deployment_target	= "7.0"
  spec.source             		= { :git => "https://github.com/dogo/AKMediaViewer.git", :tag => spec.version.to_s }
  spec.source_files       		= "AKMediaViewer/*.{h,swift}"
  spec.resources              = ['AKMediaViewer/xib/*.xib', 'AKMediaViewer/Resources/*.png']
  spec.requires_arc       		= true
  spec.dependency 'ASBPlayerScrubbing', '~> 0.1'  
end
