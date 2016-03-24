//
//  AKVideoBehavior.swift
//  AKMediaViewer
//
//  Created by Diogo Autilio on 3/22/16.
//  Copyright © 2016 AnyKey Entertainment. All rights reserved.
//

import Foundation
import UIKit

let kPlayIconTag: NSInteger = 50001

public class AKVideoBehavior : NSObject {
    
    public func addVideoIconToView(view: UIView, image: UIImage?) {
        
        var videoIcon: UIImage? = image
        var imageView: UIImageView?
        
        if((videoIcon == nil) || CGSizeEqualToSize(image!.size, CGSizeZero)) {
            videoIcon = UIImage.init(named: "icon_big_play")
        }
        imageView = UIImageView.init(image: videoIcon)
        imageView!.tag = kPlayIconTag
        imageView!.contentMode = UIViewContentMode.Center
        imageView!.autoresizingMask = [UIViewAutoresizing.FlexibleWidth, UIViewAutoresizing.FlexibleHeight]
        imageView!.frame = view.bounds
        view.addSubview(imageView!)
    }
    
}
