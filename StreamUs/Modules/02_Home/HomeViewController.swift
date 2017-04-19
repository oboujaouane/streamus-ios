//
//  HomeViewController.swift
//  StreamUs
//
//  Created by Ousama Boujaouane on 13/04/2017.
//  Copyright © 2017 Ousama Boujaouane. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation
import ResponseDetective

class HomeViewController: UIViewController, LogViewDelegate {
    // MARK: IBOutlets
    @IBOutlet weak var playStreamButton: UIButton!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var playStopButton: UIButton!
    @IBOutlet weak var showLogButton: UIButton!
    @IBOutlet weak var playerView: UIView!
    @IBOutlet weak var playerButtonsView: UIView!
    @IBOutlet weak var logView: LogView!
    // MARK: Let(s) & Var(s)
    let playerController = AVPlayerViewController()
    var timer = Timer()
    var streamUrl: URL?
    var pathForLog = String()
    var playerItem: AVPlayerItem?
    var playerStatusObservingContext = UnsafeMutablePointer<Int>(bitPattern: 1)
    // MARK: LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.redirectLogToDocuments()
        // delegate
        self.logView.logViewDelegate = self
        // Resize and center View
        self.logView.frame = self.view.frame
        self.logView.logTextView.center = CGPoint(x: self.view.bounds.midX, y: self.view.bounds.midY)
    }
    // MARK: IBActions
    @IBAction func playVideoAction(_ sender: UIButton) { // called when 'Start streaming' button is touched
        self.setupPlayer()
    }
    
    @IBAction func playPauseAction(sender: UIButton!) { // called when 'Play/Pause' button is touched
        switch sender.tag {
        case 1:
            self.playerController.player?.pause()
            self.playStopButton.setImage(#imageLiteral(resourceName: "Play"), for: .normal)
            self.playStopButton.tag = 2
        case 2:
            self.playStopButton.setImage(#imageLiteral(resourceName: "Stop"), for: .normal)
            self.playerController.player?.play()
            self.playStopButton.tag = 1
        case 3:
            self.playerItem?.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), context: &self.playerStatusObservingContext)
            self.playerController.removeFromParentViewController()
            self.playStopButton.tag = 1
            self.playStopButton.setTitle(nil, for: .normal)
            self.playStopButton.setImage(#imageLiteral(resourceName: "Stop"), for: .normal)
            self.setupPlayer()
        default:
            self.playerController.player?.pause()
            self.playStopButton.setImage(#imageLiteral(resourceName: "Play"), for: .normal)
            self.playStopButton.tag = 2
        }
    }
    
    @IBAction func showLogView(_ showLogButton: UIButton) { // called when 'Show log' button is touched and shows content of log.txt file every second
        self.showContentFile()
        self.view.addSubview(self.logView)
        self.timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.showContentFile), userInfo: nil, repeats: true)
    }
    // MARK: Funcs
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent //change status bar text to white color
    }
    
    func redirectLogToDocuments() {
        let allPaths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory: NSString = allPaths.first! as NSString
        self.pathForLog = documentsDirectory.appending(NSLocalizedString("logFileName", comment: ""))
        freopen(pathForLog.cString(using: String.Encoding.ascii)!, "a+", stderr)
    }
    
    func uiHidden(_ isHidden: Bool) {
        self.timerLabel.isHidden = isHidden
        self.infoLabel.isHidden = isHidden
        self.playStopButton.isHidden = isHidden
    }
    
    func stopTimer() {
        self.timer.invalidate()
    }
    
    func setupPlayer() {
        self.uiHidden(true)
        // in strings file
        self.streamUrl = URL(string: NSLocalizedString("streamUrl", comment: ""))!
        // Create asset to be played
        let asset = AVAsset(url: self.streamUrl!)
        let assetKeys = [
            "playable",
            "hasProtectedContent"
        ]
        // Create a new AVPlayerItem with the asset and an asset keys to be automatically loaded
        self.playerItem = AVPlayerItem(asset: asset,
                                       automaticallyLoadedAssetKeys: assetKeys)
        // Register as an observer of the player item's status property
        self.playerItem?.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: [.old, .new], context: &self.playerStatusObservingContext)
        // Associate the player item with the player
        self.playerController.player = AVPlayer(playerItem: playerItem)
        self.addPlayerToViewAndPlayIt()
    }
    
    func addPlayerToViewAndPlayIt() {
        self.playerController.view.frame = self.playerView.bounds
        self.playerController.showsPlaybackControls = false
        // add close player button
        let closePlayerButton = UIButton(type: UIButtonType.custom)
        closePlayerButton.frame = CGRect(x: 4, y: 30, width: 24, height: 24)
        closePlayerButton.setImage(#imageLiteral(resourceName: "Close"), for: .normal)
        closePlayerButton.addTarget(self, action: #selector(self.closePlayer), for:.touchUpInside)
        self.playerController.view.addSubview(closePlayerButton)
        self.playerView.addSubview(self.playerController.view)
        self.playerController.player?.play()
        self.stopPlayingIfError()
    }
    
    func stopPlayingIfError() {
        NotificationCenter.default.addObserver(forName: .AVPlayerItemNewErrorLogEntry, object: self.playerController.player?.currentItem?.accessLog(), queue: nil, using: { (_) in
            DispatchQueue.main.async {
                self.playStopButton.tag = 1
                self.playPauseAction(sender: self.playStopButton)
            }
        })
    }
    
    func closePlayer() { // called when close button in player is touched
        DispatchQueue.main.async() {
            self.playerController.player?.pause()
            self.playerItem?.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), context: &self.playerStatusObservingContext)
            self.playerController.removeFromParentViewController()
            self.playerController.view.removeFromSuperview()
        }
        self.playStopButton.tag = 1
        self.playStopButton.setImage(#imageLiteral(resourceName: "Stop"), for: .normal)
        self.uiHidden(true)
        self.showLogButton.isHidden = true
    }
    
    func showContentFile() {
        self.logView.logTextView.text = self.readFile(self.pathForLog)
        // Scroll to the bottom of textView when content updated
        let bottom = NSMakeRange(self.logView.logTextView.text.characters.count - 1, 1)
        self.logView.logTextView.scrollRangeToVisible(bottom)
        // Responsive detective
        if let streamUrl = self.streamUrl {
            let configuration = URLSessionConfiguration.default
            ResponseDetective.enable(inConfiguration: configuration)
            let session = URLSession(configuration: configuration)
            let request = URLRequest(url: streamUrl)
            session.dataTask(with: request).resume()
        }
    }
    
    func readFile(_ path: String) -> String {
        do {
            let contents:NSString = try NSString(contentsOfFile: path, encoding: String.Encoding.ascii.rawValue)
            let trimmed:String = contents.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
            let lines:String =  NSString(string: trimmed) as String
            return lines
        } catch {
            print("\(NSLocalizedString("unabletoReadFile", comment: "")): \(path)")
            return String()
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {
        // Only handle observations for the playerItemContext
        guard context == &self.playerStatusObservingContext else {
            super.observeValue(forKeyPath: keyPath,
                               of: object,
                               change: change,
                               context: context)
            return
        }
        
        if keyPath == #keyPath(AVPlayerItem.status) {
            let status: AVPlayerItemStatus
            // Get the status change from the change dictionary
            if let statusNumber = change?[.newKey] as? NSNumber {
                status = AVPlayerItemStatus(rawValue: statusNumber.intValue)!
            } else {
                status = .unknown
            }
            
            // Switch over the status
            switch status {
            case .readyToPlay:
                // Player item is ready to play.
                self.uiHidden(false)
                self.showLogButton.isHidden = false
            case .failed:
                // Player item failed.
                self.playStopButton.tag = 3
                self.playStopButton.setImage(nil, for: .normal)
                self.playStopButton.setTitle(NSLocalizedString("retry", comment: ""), for: .normal)
                self.playStopButton.isHidden = false
            case .unknown:
                print(NSLocalizedString("unknownStatus", comment: ""))
            }
        }
    }
}
