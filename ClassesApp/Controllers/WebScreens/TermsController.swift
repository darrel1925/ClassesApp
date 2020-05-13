//
//  TermsController.swift
//  ClassesApp
//
//  Created by Darrel Muonekwu on 4/20/20.
//  Copyright © 2020 Darrel Muonekwu. All rights reserved.
//

import UIKit
import WebKit


class TermsController: UIViewController {
    
    @IBOutlet weak var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpGestures()

        let webView = WKWebView(frame: view.frame)
        view.addSubview(webView)
        
        let url = URL(string: AppConstants.terms_url)!
        let request = URLRequest(url: url)
        webView.load(request)

    }
    @objc func handleDismiss() {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func exitedClicked(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    func setUpGestures() {
        let swipe1: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(self.handleDismiss))
        swipe1.direction = .down
        navigationController?.navigationBar.addGestureRecognizer(swipe1)
    }
}
