//
//  PrivacyController.swift
//  ClassesApp
//
//  Created by Darrel Muonekwu on 4/21/20.
//  Copyright © 2020 Darrel Muonekwu. All rights reserved.
//

import UIKit

class PrivacyController: UIViewController {

    @IBOutlet weak var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.prefersLargeTitles = true
        setUpGestures()
    }

    @objc func handleDismiss() {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func exitClicked(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    func setUpGestures() {
        let swipe1: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(self.handleDismiss))
        swipe1.direction = .down
        navigationController?.navigationBar.addGestureRecognizer(swipe1)
    }
}
