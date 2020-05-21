//
//  AddToListController.swift
//  ClassesApp
//
//  Created by Darrel Muonekwu on 4/27/20.
//  Copyright © 2020 Darrel Muonekwu. All rights reserved.
//

import UIKit
import AudioToolbox

class AddToListController: UIViewController {
    
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var containerView: RoundedView!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var courseNameLabel: UILabel!
    @IBOutlet weak var courseTitleLabel: UILabel!
    @IBOutlet weak var professorLabel: UILabel!
    @IBOutlet weak var courseCodeLabel: UILabel!
    @IBOutlet weak var unitsLabel: UILabel!
    @IBOutlet weak var sectionLabel: UILabel!
    @IBOutlet weak var roomLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    
    var course: Course!
    var addClassVC: AddClassController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addButton.layer.cornerRadius = 20
        // if user has premium hide get premium button
        setLabels()
        setUpGestures()
        animateViewDownward()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        addClassVC.activityIndicator.stopAnimating()
        animateViewUpwards()
    }
    
    
    func setUpGestures() {
        backgroundView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleDismiss)))
        
        let swipe: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(handleDismiss))
        swipe.direction = .down
        backgroundView.addGestureRecognizer(swipe)
    }
    
    func setLabels() {
        courseNameLabel.text = course.course_name
        courseTitleLabel.text = course.course_title
        unitsLabel.text = course.units
        professorLabel.text = course.professor
        courseCodeLabel.text = course.code
        sectionLabel.text = "\(course.course_type) \(course.section)"
        roomLabel.text = course.room
        statusLabel.text = course.status
        timeLabel.text = "\(course.days) \(course.class_time)"
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
    
    func presentPaymentErrorAlert() {
        print("error alert presenting")
        let message = "There was an error while attempting to track your classes."
        
        let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        let okay = UIAlertAction(title: "Okay", style: .default, handler: nil)
        
        alertController.addAction(okay)
        self.present(alertController, animated: true)

    }
    
    func presentSignUp() {
        let signUp = SignUpPopUpController()
        signUp.modalPresentationStyle = .overFullScreen
        signUp.addToListVC = self
        self.present(signUp, animated: true, completion: nil)
    }
    
    func alreadyTrackingClasses() -> Bool {
        if UserService.user.courseCodes.contains(course.code){
            let message = "You are already tracking course \(course.code)."
            displaySimpleError(title: "Duplicate Class", message: message) { _ in
                self.handleDismiss()
                self.addClassVC.courseCodeField.text = ""
            }
            return true
        }
        return false
    }
    
    func addClasses(dispatchGroup dg: DispatchGroup) -> Bool {
        dg.enter()

        if !ServerService.addClassToFirebase(withCourse: course, viewController: self) {
            ServerService.dispatchGroup.notify(queue: .main) {
                print("is false")
                // error occured, remove classes
                ServerService.removeClassesFromFirebase(withCourseCodes: Course.getCodes(courses: [self.course]))
                self.presentPaymentErrorAlert()
                dg.leave()
            }
        }
        dg.leave()
        return true
    }
    
    func trackClasses() {
        let dg = DispatchGroup()
        if !addClasses(dispatchGroup: dg) { return }
        
        dg.notify(queue: .main) {
            print("dispatched finished")
            AudioServicesPlaySystemSound(1519)
            Stats.logTrackedClass(course: self.course)
            self.handleDismiss()
            self.addClassVC.navigationController?.popViewController(animated: true)
        }
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
    
    @IBAction func addButtonClicked(_ sender: Any) {
        if alreadyTrackingClasses() { return }
//        if UserService.user.email == "" { presentSignUp(); return }
        
        trackClasses()
    }
}
