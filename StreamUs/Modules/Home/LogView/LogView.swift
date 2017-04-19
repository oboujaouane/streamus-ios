//
//  LogView.swift
//  StreamUs
//
//  Created by Ousama Boujaouane on 16/04/2017.
//  Copyright © 2017 Ousama Boujaouane. All rights reserved.
//

import UIKit

class LogView: UIView {

    @IBOutlet weak var logTextView: UITextView!
    @IBOutlet weak var backGroundView: UIView!
    @IBOutlet weak var backGroundTapGesture: UITapGestureRecognizer!
    
    weak var logViewDelegate: LogViewDelegate?

    @IBAction func removeView(_ sender: Any) {
        self.logViewDelegate?.stopTimer()
        self.removeFromSuperview()
    }
    
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
        self.logTextView.clipsToBounds = true
        self.logTextView.layer.cornerRadius = 3
    }
}

protocol LogViewDelegate: class {
    func stopTimer()
}
