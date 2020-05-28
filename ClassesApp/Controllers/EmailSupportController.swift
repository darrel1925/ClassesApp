//
//  EmailSupportController.swift
//  ClassesApp
//
//  Created by Darrel Muonekwu on 5/4/20.
//  Copyright © 2020 Darrel Muonekwu. All rights reserved.
//

import UIKit

class EmailSupportController: UIViewController {
    
    @IBOutlet var backgroundView: UIView!
    @IBOutlet weak var containerView: RoundedView!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    
    var placeholderLabel : UILabel!
    var placeHolderText: String = "Sending feedback? Seeking support? Want to see a new feature? Find a bug? Whatever it is, we want to hear from you. Let us know what we can do for you!"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.prefersLargeTitles = true
        textView.text = placeHolderText
        textView.textColor = #colorLiteral(red: 0.7685185075, green: 0.7685293555, blue: 0.7766974568, alpha: 1)
        textView.delegate = self
        textView.returnKeyType = .done
        
        textView.layer.borderColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
        textView.layer.borderWidth = 1
        textView.layer.cornerRadius = 10
        setUpGestures()
        
    }
    
    func setUpGestures() {
        let tap1: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        let tap2: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        let swipe1: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(self.handleDismiss))
        let swipe2: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        let swipe3: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        let swipe4: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        swipe1.direction = .down
        
        navigationController?.navigationBar.addGestureRecognizer(swipe1)
        navigationController?.navigationBar.addGestureRecognizer(tap2)
        view.addGestureRecognizer(swipe2)
        view.addGestureRecognizer(tap1)
        textView.addGestureRecognizer(swipe3)
        textField.addGestureRecognizer(swipe4)

        
    }
    
    func send_email(){
        var subject: String!
        if UserService.user == nil {
            subject = "\(textField.text ?? "") / Not Logged In"
        }
        else {
            subject = "\(textField.text ?? "") / \(UserService.user.school)"
        }
        
        let email = UserService.user.email
        let message = "\(textView.text ?? "")  -(hidden: \(email))" 
        ServerService.sendSupportEmail(subject: subject, message: message) { (json, error) in
            print("json", json)
            if let _ = error {
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                    let message = "Could not send message, please try again later"
                    self.displayError(title: "Could not send message", message: message)
                }
                return
            }
            
            let didSendEmail = json?[DataBase.did_send_email] as? Bool ?? false
            
            if didSendEmail {
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                    self.displaySimpleError(title: "Message Sent", message: "") { (_) in
                        self.handleDismiss()
                    }
                }
                return
            }
            else {
                DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                 let message = "Please try again later"
                 self.displayError(title: "Could not send message", message: message)
                }
                return
            }
        }
    }
    
    @objc func dismissKeyboard() {
        print("dis")
        view.endEditing(true)
    }
    
    @objc func handleDismiss() {
        dismiss(animated: true, completion: nil )
    }
    
    @IBAction func exitButtonClicked(_ sender: Any) {
        handleDismiss()
    }
    
    @IBAction func sendMessageClicked(_ sender: Any) {
        if textView.text ?? placeHolderText == placeHolderText {
            self.displayError(title: "Please enter a message", message: "")
            return
        }
        activityIndicator.startAnimating()
        send_email()
    }
}



extension EmailSupportController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == placeHolderText {
            textView.text = ""
            textView.textColor = .black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text == "" {
            textView.text = placeHolderText
            textView.textColor = #colorLiteral(red: 0.7685185075, green: 0.7685293555, blue: 0.7766974568, alpha: 1)
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n"{
            textView.resignFirstResponder()
        }
        return true
    }
  
}
