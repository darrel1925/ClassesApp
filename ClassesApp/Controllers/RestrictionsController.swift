//
//  RestrictionsController.swift
//  ClassesApp
//
//  Created by Darrel Muonekwu on 5/24/20.
//  Copyright © 2020 Darrel Muonekwu. All rights reserved.
//

import UIKit

class RestrictionsController: UIViewController {

    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var containerView: RoundedView!
    @IBOutlet weak var tableView: UITableView!
    
    var classDetailsVC: ClassDetailsController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpGestures()
        animateViewDownward()
        setUpTableView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateViewUpwards()
    }
    
    func setUpTableView() {
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    func setUpGestures() {
        backgroundView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleDismiss)))
        
        let swipe: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(handleDismiss))
        swipe.direction = .down
        backgroundView.addGestureRecognizer(swipe)
    }
    
    func animateViewUpwards() {
        guard let window = UIApplication.shared.keyWindow else { return }
        
        let height: CGFloat = containerView.frame.height
        let y = window.frame.height - height
        
        UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            
            self.backgroundView.alpha = 0.1
            self.containerView.frame = CGRect(x: 0, y: y, width: window.frame.width, height: height)
            
        }, completion: nil)
    }
    
    func animateViewDownward() {
        backgroundView.alpha = 0
        guard let window = UIApplication.shared.keyWindow else { return }
        containerView.frame = CGRect(x: 0, y: window.frame.height, width: window.frame.width, height: 0)
    }
    
    @objc func handleDismiss() {
        
        UIView.animate(withDuration: 0.15, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            self.backgroundView.alpha = 0
            
        }, completion: {_ in
                UIView.animate(withDuration: 0.15, animations: {
                    let restrictionHeight = CGFloat(230)
                    let x = self.classDetailsVC.containerView.frame.midX
                    let y = self.classDetailsVC.containerView.frame.midY + restrictionHeight
                    let adjustedCenter = CGPoint(x: x, y: y)
                    
                    self.classDetailsVC.containerView.center = adjustedCenter
                    self.dismiss(animated: true, completion: nil)
            })
        })
    }
}

extension RestrictionsController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        Restrictions.restrictions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.row
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsLabelCell") as! SettingsLabelCell
        
        cell.titleLabel.text = Restrictions.restrictions[row]
        
        return cell
    }
    

}
