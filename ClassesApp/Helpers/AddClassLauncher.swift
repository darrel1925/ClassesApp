//
//  AddClassLauncher.swift
//  ClassesApp
//
//  Created by Darrel Muonekwu on 3/29/20.
//  Copyright © 2020 Darrel Muonekwu. All rights reserved.
//

import UIKit

class AddClassLauncher: UIViewController {
    
    var blackView : UIView!
    var cartCotainer: UIView!
    var addClassController: AddClassController!

    func showAddClassView(cartView: UIView, addClassController: AddClassController, blackView: UIView) {
        // show menu
        cartView.isHidden = false
        self.cartCotainer = cartView
        self.blackView = blackView
        
        
        if let window = UIApplication.shared.keyWindow {
            blackView.backgroundColor = UIColor(white: 0, alpha: 0.5)
            
            window.addSubview(blackView)
            window.addSubview(cartCotainer)
            
            blackView.frame = window.frame
            blackView.alpha = 0

            let height: CGFloat = 275
            let y = window.frame.height - height
            cartCotainer.frame = CGRect(x: 0, y: window.frame.height, width: window.frame.width, height: height)

            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                self.blackView.alpha = 1
                self.cartCotainer.frame = CGRect(x: 0, y: y, width: window.frame.width, height: height)

            }, completion: nil)
            let swipe: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: addClassController, action: #selector(handleDismiss1))
            swipe.direction = .down

            blackView.addGestureRecognizer(swipe)
            blackView.addGestureRecognizer(UITapGestureRecognizer(target: addClassController, action: #selector(handleDismiss1)))

        }
    }

    
    @objc func handleDismiss1() { // <-- this func is not executed
        /* -->  Moved to AddClassCrontroller  <-- */
        print("tapped")
        UIView.animate(withDuration: 0.5) {
            self.blackView.alpha = 0
            
            if let window = UIApplication.shared.keyWindow {
                self.cartCotainer.frame = CGRect(x: 0,
                                                y: window.frame.height,
                                                width: window.frame.width,
                                                height: window.frame.height)
            }
            

        }
    }
}
