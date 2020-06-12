//
//  WelcomeScreen31.swift
//  ClassesApp
//
//  Created by Darrel Muonekwu on 5/29/20.
//  Copyright © 2020 Darrel Muonekwu. All rights reserved.
//

import UIKit

class WelcomeScreen31: UIViewController {

    // change when I call this var from get premium page
    var changeSkipButtonTitle: Bool = false
    
    @IBOutlet weak var skipButton: RoundedButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        changeButton()
    }
    
    func changeButton() {
        if changeSkipButtonTitle {
            setGestures()
            skipButton.setTitle("Go Back", for: .normal)
            skipButton.setTitleColor(.black, for: .normal)
        }
    }
    
    func setGestures() {
        let swipe1: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(self.handleDismiss))
        swipe1.direction = .down
        view.addGestureRecognizer(swipe1)
    }
    
    @objc func handleDismiss() {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func skipClicked(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}
