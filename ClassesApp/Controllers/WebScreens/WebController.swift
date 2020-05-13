//
//  WebController.swift
//  ClassesApp
//
//  Created by Darrel Muonekwu on 4/26/20.
//  Copyright © 2020 Darrel Muonekwu. All rights reserved.
//

import UIKit
import WebKit

class WebController: UIViewController {
            
    var urlStr: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpGestures()
        presentWebView()
        Stats.logSignUpClicked()
  
    }
    
    fileprivate func setUpGestures() {
        let swipe1: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(self.handleDismiss))
        swipe1.direction = .down
        navigationController?.navigationBar.addGestureRecognizer(swipe1)
    }
    
    fileprivate func presentWebView() {
        if urlStr == nil { return }
            
            let webView = WKWebView(frame: view.frame)
            view.addSubview(webView)
            
            let url = URL(string: urlStr)!
            let request = URLRequest(url: url)
            webView.load(request)

    }
    
    @objc func handleDismiss() {
        dismiss(animated: true, completion: nil)
    }

    
    @IBAction func exitClicked(_ sender: Any) {
        print("pressed")
        dismiss(animated: true, completion: nil)
    }
    
}
