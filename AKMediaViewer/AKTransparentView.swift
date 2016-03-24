//
//  AKTransparentView.swift
//  AKMediaViewer
//
//  Created by Diogo Autilio on 3/23/16.
//  Copyright © 2016 AnyKey Entertainment. All rights reserved.
//

import Foundation
import UIKit

public class AKTransparentView : UIView {
    
    override public func hitTest(point: CGPoint, withEvent event: UIEvent?) -> UIView? {
        var view: UIView? = super.hitTest(point, withEvent: event)
        
        if(view == self) {
            view = nil
        }
        return view
    }
}