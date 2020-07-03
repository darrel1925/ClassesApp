//
//  WhatsNewController.swift
//  ClassesApp
//
//  Created by Darrel Muonekwu on 5/30/20.
//  Copyright © 2020 Darrel Muonekwu. All rights reserved.
//

import UIKit

class WhatsNewController: UIViewController {

    
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var containerView: RoundedView!
    @IBOutlet weak var versionLabel: UILabel!
    
        override func viewDidLoad() {
            super.viewDidLoad()
                setUpGestures()
            }
            
            override func viewDidAppear(_ animated: Bool) {
                super.viewDidAppear(animated)
                animateViewIn()
            }
            
            func animateViewIn() {
                UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                    
                    self.backgroundView.alpha = 0.25
                    
                }, completion: nil)
            }
            
            func setUpGestures() {
                let tap1 = UITapGestureRecognizer(target: self, action: #selector(handleDismiss))
                let swipe1: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(handleDismiss))
                swipe1.direction = .down
                backgroundView.addGestureRecognizer(swipe1)
                backgroundView.addGestureRecognizer(tap1)
            }
            
        func presentWelcome31() {
            let vc = storyboard?.instantiateViewController(withIdentifier: "WelcomeScreen31") as! WelcomeScreen31
            vc.modalPresentationStyle = .overCurrentContext
            vc.changeSkipButtonTitle = true
            self.present(vc, animated: true, completion: nil)
        }
        
        @objc func handleDismiss() {
            UIView.animate(withDuration: 0.15, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                
                self.backgroundView.alpha = 0
                
            }, completion: {_ in
                UIView.animate(withDuration: 0.15, delay: 1, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                    
                    self.dismiss(animated: true, completion: nil)
                    
                }, completion: nil)
            })
        }

    @IBAction func premiumDetailsButton(_ sender: Any) {
        presentWelcome31()
    }
    
    @IBAction func exitClicked(_ sender: Any) {
        handleDismiss()
    }
}

