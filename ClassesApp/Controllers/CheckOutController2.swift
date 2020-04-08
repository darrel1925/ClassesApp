//
//  CheckOutController2.swift
//  ClassesApp
//
//  Created by Darrel Muonekwu on 4/4/20.
//  Copyright © 2020 Darrel Muonekwu. All rights reserved.
//

import UIKit

class CheckOutController2: UIViewController {
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var backgroundView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        backgroundView.alpha = 0
        guard let window = UIApplication.shared.keyWindow else { return }
        
        let height: CGFloat = 0
        containerView.frame = CGRect(x: 0, y: window.frame.height, width: window.frame.width, height: height)
        backgroundView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleDismiss2)))
        
        let swipe: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(handleDismiss2))
        swipe.direction = .down
        backgroundView.addGestureRecognizer(swipe)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard let window = UIApplication.shared.keyWindow else { return }
        
        let height: CGFloat = 275
        let y = window.frame.height - height
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            
            self.backgroundView.alpha = 0.5
            self.containerView.frame = CGRect(x: 0, y: y, width: window.frame.width, height: height)
            
        }, completion: {_ in
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                
                self.backgroundView.alpha = 0.5
                self.containerView.frame = CGRect(x: 0, y: y, width: window.frame.width, height: height)
                
            }, completion: nil)
        })
    }
    
    @objc func handleDismiss2() {
        print("tapped3")
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            
            self.backgroundView.alpha = 0
            
        }, completion: {_ in
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                
                self.dismiss(animated: true, completion: nil)
                
            }, completion: nil)
        })
    }
}
