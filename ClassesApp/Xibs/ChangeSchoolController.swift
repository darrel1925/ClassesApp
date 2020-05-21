//
//  ChangeSchoolController.swift
//  ClassesApp
//
//  Created by Darrel Muonekwu on 4/30/20.
//  Copyright © 2020 Darrel Muonekwu. All rights reserved.
//

import UIKit
import FirebaseFirestore
class ChangeSchoolController: UIViewController {
    
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var containerView: RoundedView!
    @IBOutlet weak var schoolField: UITextField!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var settingsVC: SettingsController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpGestures()
        animateViewDownward()
        setUpSchoolPicker()
        setLabels()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateViewUpwards()
        setUpToolBar()
    }
    
    
    func setLabels() {
        schoolField.text = UserService.user.school
    }
    
    func setUpSchoolPicker() {
        let schoolPicker = UIPickerView()
        schoolPicker.delegate = self
        schoolField.inputView = schoolPicker
    }
    
    func setUpToolBar() {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(dismissKeyboard))
        
        toolbar.setItems([doneButton], animated: true)
        toolbar.isUserInteractionEnabled = true
        
        schoolField.inputAccessoryView = toolbar
        schoolField.becomeFirstResponder() //puts cursor on text field


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
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            
            self.backgroundView.alpha = 0.5
            self.containerView.frame = CGRect(x: 0, y: y, width: window.frame.width, height: height)
            
        }, completion: nil)
    }
    
    func animateViewDownward() {
        backgroundView.alpha = 0
        guard let window = UIApplication.shared.keyWindow else { return }
        containerView.frame = CGRect(x: 0, y: window.frame.height, width: window.frame.width, height: 0)
    }
    
    func presentUpdateAlert() {
        let message = "Clicking update will remove your currently tracked classes and you will begin searching for classes at \(schoolField.text ?? "" )."
        let alert = UIAlertController(title: "Update School", message: message, preferredStyle: .alert)
        let updateAction = UIAlertAction(title: "Update", style: .destructive, handler: {_ in
            self.activityIndicator.startAnimating()
            self.updateSchool()
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        
        alert.addAction(cancelAction)
        alert.addAction(updateAction)
        present(alert, animated: true, completion: nil)
    }
    
    func updateSchool() {
        let db = Firestore.firestore()
        let docRef = db.collection(DataBase.User).document(UserService.user.email)
        ServerService.removeClassesFromFirebase(withCourseCodes: UserService.user?.courseCodes ?? [])

        docRef.updateData([DataBase.school: schoolField.text ?? UserService.user.school]) { (err) in
            if err != nil {
                self.activityIndicator.stopAnimating()
                self.displayError(title: "Error Updating School", message: "There was an error you school please try again later.")
                return
            }
            Stats.setUserProperty(school: self.schoolField.text ?? UserService.user.school)
            self.activityIndicator.stopAnimating()
            self.settingsVC.tableView.reloadData()
            self.handleDismiss()
        }
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc func handleDismiss() {
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            
            self.view.alpha = 0
            
        }, completion: {_ in
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                
                self.dismiss(animated: true, completion: nil)
                
            }, completion: nil)
        })
    }
    @IBAction func updateSchoolClicked(_ sender: Any) {
        if schoolField.text?.isEmpty ?? true { return }
        if !AppConstants.supported_schools.contains(schoolField.text ?? "") { return }
        
        if schoolField.text == UserService.user.school { handleDismiss() }
        else { presentUpdateAlert() }
    }
}

extension ChangeSchoolController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return AppConstants.supported_schools.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return AppConstants.supported_schools[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        schoolField.text = AppConstants.supported_schools[row]
    }
}

