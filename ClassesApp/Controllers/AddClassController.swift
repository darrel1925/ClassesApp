//
//  AddClassController.swift
//  ClassesApp
//
//  Created by Darrel Muonekwu on 3/30/20.
//  Copyright © 2020 Darrel Muonekwu. All rights reserved.
//

import UIKit
import AudioToolbox
import FirebaseAuth
import FirebaseFirestore

class AddClassController: UIViewController {
    
    @IBOutlet weak var checkAvailabilityButton: RoundedButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var statusTitle: UILabel!
    @IBOutlet weak var courseCodeField: UITextField!
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var quarterLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    var courses = [Course]()
    
    // Change store to get credits or go premium
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpButtons()
        setLabels()
    }
    
    func setLabels() {
        quarterLabel.text = AppConstants.quarter.capitalizingFirstLetter()
        
        if UserService.user.school == Schools.UCI {
        descriptionLabel.text = "Enter the 5 digit course code for the class you would like to track"
        }
        else if UserService.user.school == Schools.UCLA {
            descriptionLabel.text = "Enter the 9 digit course code for the class you would like to track"
        }
    }
    
    func setUpButtons() {
        checkAvailabilityButton.layer.cornerRadius = 10
        checkAvailabilityButton.titleLabel?.numberOfLines = 1
        checkAvailabilityButton.titleLabel?.adjustsFontSizeToFitWidth = true
        checkAvailabilityButton.titleLabel?.lineBreakMode = .byClipping
        courseCodeField.becomeFirstResponder()
    }
    
    func presnentAddToList(course: Course) {
        let addToListVC = AddToListController()
        addToListVC.modalPresentationStyle = .overFullScreen
        addToListVC.course = course
        addToListVC.addClassVC = self
        self.present(addToListVC, animated: true, completion: nil)
    }
    
    func presentClassDetailController() {
        let url_str = AppConstants.class_look_up_pages[UserService.user.school]
        if let url = URL(string: url_str!) {
          UIApplication.shared.open(url)
        }
    }

    func handle_dismiss() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func makeConnection() {
        let code = courseCodeField.text!
        ServerService.getClassInfo(course_code: code) { (json, notFound,error) in
            if notFound {
                DispatchQueue.main.async { // Correct
                    let message = "\(code) not offered. Double check the course code you entered and try again."
                    self.displayError(title: "Class Not Found", message: message)
                    self.activityIndicator.stopAnimating()
                }
                return
            }
            else if error != nil {
                DispatchQueue.main.async { // Correct
                    let message = "Looks like there is a connection issue. Things to try:\n\n1. Restart the app\n2. Check that you have a reliable internet connection\n3. Contact support."
                    self.displayError(title: "Connection Error", message: message)
                    self.activityIndicator.stopAnimating()
                }
            }
            
            DispatchQueue.main.async { // Correct
                let course = Course(courseDict: json ?? [:])
                self.presnentAddToList(course: course)
            }
            print(json ?? [:])
        }
    }
    
    @IBAction func tapHereClicked(_ sender: Any) {
        presentClassDetailController()
    }
    
    @IBAction func checkAvailabilityClicked(_ sender: Any) {
        activityIndicator.startAnimating()
        if courseCodeField.text?.isEmpty ?? true {
            activityIndicator.stopAnimating()
            let message = "Looks like you forgot to enter your course code. Let's try again!"
            self.displayError(title: "Empty Field", message: message)
            return }
        
        if courseCodeField.text?.count != 5  || courseCodeField.text?.isOnlyNumeric ?? true {
            activityIndicator.stopAnimating()
            let message = "Make sure you enter a 5 digit course! Ex. 34250 or 14723"
            self.displayError(title: "Invalid Entry", message: message)
            return }
        
        if Course.getCodes(courses: courses).contains(courseCodeField.text ?? "") {
            activityIndicator.stopAnimating()
            let message = "You've already added this course! Check the availibility of a different class before adding again."
            self.displayError(title: "Duplicate Course", message: message)
            return }
        
        makeConnection()
    }
}

extension AddClassController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return false
    }
}

