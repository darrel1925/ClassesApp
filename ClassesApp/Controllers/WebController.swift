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
    }
    
    fileprivate func setUpGestures() {
        let swipe1: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(self.handleDismiss))
        swipe1.direction = .down
        navigationController?.navigationBar.addGestureRecognizer(swipe1)
    }
    
    fileprivate func presentWebView() {
        if let urlStr =  AppConstants.registration_pages[UserService.user.school] {
            if urlStr == "" { return }
            
            let webView = WKWebView(frame: view.frame)
            view.addSubview(webView)
            
            let url = URL(string: urlStr)!
            let request = URLRequest(url: url)
            webView.load(request)
        }
        else {
            print("Did not pass in a string")
        }
    }
    
    @objc func handleDismiss() {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func exitClicked(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
}
