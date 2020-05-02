//
//  Animations.swift
//  ClassesApp
//
//  Created by Darrel Muonekwu on 5/1/20.
//  Copyright © 2020 Darrel Muonekwu. All rights reserved.
//

import Foundation
import UIKit

let Animations = _Animations()
final class _Animations {
    
    var blackView: UIView!
    var directionsImage: UIImageView!

    
    // HOME VIEW CONTROLLER
    func animateHomeTapDirections(HomeViewController homeVC: HomePageController) {
        guard let window = UIApplication.shared.keyWindow else { return }

        blackView = UIView()
        blackView.frame = window.frame
        blackView.backgroundColor = .black
        blackView.alpha = 0
        blackView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleAnimationDismiss)))

        
        let image = UIImage(named: "tapDirections")
        directionsImage = UIImageView(image: image)
        directionsImage.frame = CGRect(x: homeVC.view.center.x, y: homeVC.view.center.y, width: homeVC.view.frame.width * 0.9, height: 125)
        directionsImage.center = CGPoint(x: homeVC.view.center.x, y: homeVC.tableView.frame.minY + 80)
        directionsImage.contentMode = .scaleAspectFit
        directionsImage.alpha = 0
        homeVC.view.addSubview(blackView)
        homeVC.view.addSubview(directionsImage)

        UIView.animate(withDuration: 0.6, animations: {
            
            self.blackView.alpha = 0.5
            self.directionsImage.alpha = 1
        })
    }
    
    @objc func handleAnimationDismiss() {
        UIView.animate(withDuration: 0.6, animations: {
            self.blackView.alpha = 0
            self.directionsImage.alpha = 0
        })
    }
}
