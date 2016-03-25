//
//  AKVideoControlView.swift
//  AKMediaViewer
//
//  Created by Diogo Autilio on 3/18/16.
//  Copyright © 2016 AnyKey Entertainment. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

public class AKVideoControlView : UIView {
    
    @IBOutlet public var scrubbing: ASBPlayerScrubbing!
    @IBOutlet var slider: UISlider!
    @IBOutlet var remainingTimeLabel: UILabel!
    @IBOutlet var durationLabel: UILabel!
    @IBOutlet var playPauseButton: UIButton!
    
    override public func awakeFromNib() {
        super.awakeFromNib()
        scrubbing.addObserver(self, forKeyPath: "player", options: NSKeyValueObservingOptions.New, context: nil)
    }
    
    deinit {
        scrubbing.removeObserver(self, forKeyPath: "player")
        scrubbing.player.removeObserver(self, forKeyPath: "rate")
    }
    
    class func videoControlView() -> AKVideoControlView {
        let objects: NSArray = NSBundle.mainBundle().loadNibNamed("AKVideoControlView", owner: nil, options: nil)
        return objects.firstObject as! AKVideoControlView
    }
    
    // MARK: - IBActions
    
    @IBAction func switchTimeLabel(sender: AnyObject) {
        self.remainingTimeLabel.hidden = !self.remainingTimeLabel.hidden
        self.durationLabel.hidden = !self.remainingTimeLabel.hidden
    }
    
    // MARK: - KVO
    
    override public func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if (keyPath == "player") {
            if(scrubbing.player != nil) {
                scrubbing.player.addObserver(self, forKeyPath: "rate", options: NSKeyValueObservingOptions.New, context: nil)
            }
        } else {
            let player = object as! AVPlayer
            playPauseButton.selected = (player.rate != 0)                    
        }
    }
}