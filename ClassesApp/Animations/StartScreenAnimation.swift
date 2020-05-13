//
//  StartScreenAnimation.swift
//  ClassesApp
//
//  Created by Darrel Muonekwu on 3/31/20.
//  Copyright © 2020 Darrel Muonekwu. All rights reserved.
//

import UIKit

class AnimateStartPage {
    var startVC: SplashScreenController
    var animationWillContinue: Bool!
    let dispatchGroup = DispatchGroup()
    
    init(startVC: SplashScreenController) {
        self.startVC = startVC
        self.animationWillContinue = true

    }
    
    func stopAnimation() {
        animationWillContinue = false
    }
    
    func beginAnimation() {
        animationWillContinue = true
        continueAnimation()
    }
    
    func continueAnimation(){
        dispatchGroup.enter()
        UIView.animate(withDuration: 3.5, animations:{
            let toImage = UIImage(named:"stars3")
           UIView.transition(with: self.startVC.backgroundImageView,
                              duration: 10,
                              options: .transitionCrossDissolve,
                              animations: {
                               self.startVC.backgroundImageView.image = toImage
                               self.startVC.backgroundImageView.contentMode = .scaleAspectFill
            }, completion: nil)
            
        })
        self.dispatchGroup.leave()

        dispatchGroup.notify(queue: .main, execute: {
            self.animate1()

        })
    }

    func animate1(){
         self.dispatchGroup.enter()
        UIView.animate(withDuration: 3.5, animations:{
             let toImage = UIImage(named:"stars2")
            UIView.transition(with: self.startVC.backgroundImageView,
                               duration: 10,
                               options: .transitionCrossDissolve,
                               animations: {
                                self.startVC.backgroundImageView.image = toImage
                                self.startVC.backgroundImageView.contentMode = .scaleAspectFill
             }, completion: {_ in
                 self.dispatchGroup.leave()
             })
         })

         dispatchGroup.notify(queue: .main, execute: {
             if self.animationWillContinue {
                 self.animate2()
             }
         })
     }
    
     func animate2(){
            self.dispatchGroup.enter()

        UIView.animate(withDuration: 3.3, animations:{
                let toImage = UIImage(named:"stars1")
                UIView.transition(with: self.startVC.backgroundImageView,
                                  duration: 10,
                                  options: .transitionCrossDissolve,
                                  animations: {
                                    self.startVC.backgroundImageView.image = toImage
                                    self.startVC.backgroundImageView.contentMode = .scaleAspectFill
                }, completion: {_ in
                
                     self.dispatchGroup.leave()
                })
            })

            dispatchGroup.notify(queue: .main, execute: {
                self.animate3()
             print("Done2")
            })
        }
    func animate3(){
           self.dispatchGroup.enter()

           UIView.animate(withDuration: 4, animations:{
               let toImage = UIImage(named:"stars3")
               UIView.transition(with: self.startVC.backgroundImageView,
                                 duration: 10,
                                 options: .transitionCrossDissolve,
                                 animations: {
                                   self.startVC.backgroundImageView.image = toImage
                                   self.startVC.backgroundImageView.contentMode = .scaleAspectFill
               }, completion: {_ in
               
                    self.dispatchGroup.leave()
               })
           })

           dispatchGroup.notify(queue: .main, execute: {
               self.continueAnimation()
            print("Done2")
           })
       }
}
