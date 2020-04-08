//
//  SlideInTransition.swift
//  ClassesApp
//
//  Created by Darrel Muonekwu on 3/30/20.
//  Copyright © 2020 Darrel Muonekwu. All rights reserved.
//

import UIKit

class SlideInTransition: NSObject, UIViewControllerAnimatedTransitioning {
    // presenting = true | dismissing = false
    var isPresenting = false
    let blackView = UIView()
    var toDimiss: UIViewController?
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let  toViewController = transitionContext.viewController(forKey: .to),
              let fromViewController = transitionContext.viewController(forKey: .from) else { return }
        
        self.toDimiss = toViewController
        let containerView = transitionContext.containerView
        
        let finalWidth = toViewController.view.bounds.width * 0.8
        let finalHeight = toViewController.view.bounds.height
        
        if isPresenting {
            blackView.backgroundColor = .black
            blackView.alpha = 0
            
            blackView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleDismiss)))

            
            // add background view and menuVC to container
            containerView.addSubview(blackView)
            containerView.addSubview(toViewController.view)
            
            // init frame off the screen
            toViewController.view.frame = CGRect(x: -finalWidth, y: 0, width: finalWidth, height: finalHeight)
            blackView.frame = containerView.frame
        }
        
        // Animate onto screen
        let transform = {
            self.blackView.alpha = 0.5
            toViewController.view.transform = CGAffineTransform(translationX: finalWidth, y: 0)
            let swipe1: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(self.handleDismiss))
            let swipe2: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(self.handleDismiss))
            swipe1.direction = .left
            swipe2.direction = .left
            toViewController.view.addGestureRecognizer(swipe1)
            self.blackView.addGestureRecognizer(swipe2)
        }
        
        // Animate back off screen
        
        let identity = {
            self.blackView.alpha = 0
            fromViewController.view.transform = .identity
        }
        
        // animation of transition
        let duration = transitionDuration(using: transitionContext)
        let isCancelled = transitionContext.transitionWasCancelled
                
        UIView.animate(withDuration: duration, animations: {
            self.isPresenting ? transform() : identity()
        }) { (_) in
            transitionContext.completeTransition(!isCancelled)
        }
    }
    
    @objc func handleDismiss() {
        toDimiss?.dismiss(animated: true, completion: nil )
    }
}
