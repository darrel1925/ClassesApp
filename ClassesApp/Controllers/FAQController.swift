//
//  FAQController.swift
//  ClassesApp
//
//  Created by Darrel Muonekwu on 5/9/20.
//  Copyright © 2020 Darrel Muonekwu. All rights reserved.
//

import UIKit

class FAQController: UIViewController {

    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var containerView: RoundedView!
    @IBOutlet weak var tableView: UITableView!
    
    let faqQuestions: [[String]] = [
        [
            "What is the difference between TrackMy Premium and TrackMy Free?",
            "1. Premium users will receive all notifications first, non-premium will receive notifications directly after.\n\n2. Premium users can track an unlimited number of classes each quarter, Free users can only track one class at a time.\n\n3. Premium users will be notified when restrictions are dropped from a class AND when a class status changes, TrackMy Free users will only be notified when a class status changes."
        ],
        [
            "Will premium last the entire year?",
            "No, purchasing premium will allow you to track as many classes as you want for the current quarter only. "
        ],
        [
            "Will my card be automatically charged next quarter?",
            "No, your purchase is a one time purchase and your card WILL NOT ever be automatically charged in following quarters."
        ],
        [
            "When exactly will my premium be reset?",
            "Premium is reset each quarter when it's time to register for classes for the following quarter."
        ],
        [
            "Have more questions?",
            "Feel free to contact support, we're happy to answer your questions."
        ]
    ]
    
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
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleDismiss))
        let swipe1: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(handleDismiss))
        let swipe2: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(handleDismiss))
        swipe1.direction = .down
        swipe2.direction = .down
        backgroundView.addGestureRecognizer(tap)
        backgroundView.addGestureRecognizer(swipe1)
        containerView.addGestureRecognizer(swipe2)
    }
    
    func animateViewUpwards() {
        guard let window = UIApplication.shared.keyWindow else { return }
        
        let height: CGFloat = containerView.frame.height
        let y = window.frame.height - height
        
        UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            
            self.backgroundView.alpha = 0.5
            self.containerView.frame = CGRect(x: 0, y: y, width: window.frame.width, height: height)
            
        }, completion: nil)
    }
    
    func animateViewDownward() {
        backgroundView.alpha = 0
        guard let window = UIApplication.shared.keyWindow else { return }
        containerView.frame = CGRect(x: 0, y: window.frame.height, width: window.frame.width, height: 0)
    }
    
    @objc func handleDismiss() {
        
        UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            
            self.backgroundView.alpha = 0

        }, completion: {_ in
            UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                
                self.dismiss(animated: true, completion: nil)
                
            }, completion: nil)
        })
    }
}

extension FAQController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return faqQuestions.count * 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row  = indexPath.row
        let cell = tableView.dequeueReusableCell(withIdentifier: "PlainTextCell") as! PlainTextCell
        
        var index: Double = (Double(row/2))
        index.round(.down)
        
        if row % 2 == 0 {
            cell.descriptionLabel.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
            cell.descriptionLabel.text = faqQuestions[Int(index)][0]
        }
        else {
            cell.descriptionLabel.text = faqQuestions[Int(index)][1]
            cell.descriptionLabel.textColor = #colorLiteral(red: 0.6666666865, green: 0.6666666865, blue: 0.6666666865, alpha: 1)
        }
        
        return cell
    }
    

}
