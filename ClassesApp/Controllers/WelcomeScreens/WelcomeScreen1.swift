//
//  WelcomeScreen1.swift
//  ClassesApp
//
//  Created by Darrel Muonekwu on 4/18/20.
//  Copyright © 2020 Darrel Muonekwu. All rights reserved.
//

import UIKit

class WelcomeScreen1: UIViewController {
    
    @IBOutlet weak var swipeImageView: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        swipeImageView.alpha = 0.1
        beginAnimation()
    }
    
    func beginAnimation() {
        UIView.animate(withDuration: 8, animations: {
            self.swipeImageView.alpha = 0.0
            
        }) { _ in
            self.animateOut()
        }
    }
    
    func animateIn() {
        UIView.animate(withDuration: 2, animations: {
            self.swipeImageView.alpha = 0.8
            
        }) { _ in
            self.animateOut()
        }
    }
    
    func animateOut() {
        UIView.animate(withDuration: 2, animations: {
            self.swipeImageView.alpha = 0.1
            
        }) { _ in
            self.animateIn()
        }
    }
    
    @IBAction func skipClicked(_ sender: Any) {
        print("dismiss")
        
        self.dismiss(animated: true, completion: nil)
    }
}
