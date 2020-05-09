//
//  ClassDetailController.swift
//  ClassesApp
//
//  Created by Darrel Muonekwu on 4/28/20.
//  Copyright © 2020 Darrel Muonekwu. All rights reserved.
//

import UIKit

class ClassDetailController: UIViewController {
    
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var copyButton: UIButton!
    @IBOutlet weak var coppiedLabel: RoundedLabel!
    @IBOutlet weak var containerView: RoundedView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var professorLabel: UILabel!
    @IBOutlet weak var codeLabel: UILabel!
    @IBOutlet weak var unitsLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var sectionLabel: UILabel!
    @IBOutlet weak var roomLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    
    var course: Course!
    var homeVC: HomePageController!
    var indexPath: IndexPath!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setLabels()
        setUpGestures()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        animateViewIn()
    }
    
    
    func animateViewIn() {
        
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {

            self.backgroundView.alpha = 0.25
            
        }, completion: nil)
    }
    
    func setLabels() {
        coppiedLabel.alpha = 0
        coppiedLabel.layer.masksToBounds = true
        coppiedLabel.layer.cornerRadius = 10
        nameLabel.text = course.course_name
        titleLabel.text = course.course_title
        unitsLabel.text = course.units
        professorLabel.text = course.professor
        codeLabel.text = course.code
        sectionLabel.text = "\(course.course_type) \(course.section)"
        roomLabel.text = course.room
        statusLabel.text = course.status
        timeLabel.text = "\(course.days) \(course.class_time)"
    }
    
    func setUpGestures() {
        backgroundView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleDismiss)))
        
            let swipe1: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(handleDismiss))
    
            swipe1.direction = .down
            backgroundView.addGestureRecognizer(swipe1)

        
    }

    func animateIn() {
        coppiedLabel.text = "\(course.code) copied to clipboard"
        print("clciked")
        UIView.animate(withDuration: 0.5,
                       delay: 0.0,
                       animations: {self.coppiedLabel.alpha = 1},
                       completion: {finished in self.animateOut()})
    }

    func animateOut() {
        UIView.animate(withDuration: 0.5,
                       delay: 0.5,
                       animations: {self.coppiedLabel.alpha = 0},
                       completion: nil)
    }
    
    func presentWebController()
    {
        let vc = homeVC.storyboard?.instantiateViewController(withIdentifier: "WebController") as! WebController
        let navController = UINavigationController(rootViewController: vc)
        navController.modalPresentationStyle = .fullScreen
        
        
        UIView.animate(withDuration: 0.5, animations: {
            self.backgroundView.alpha = 0
        }) { _ in
            self.dismiss(animated: true, completion: {
                self.homeVC.present(navController, animated: true, completion: nil)
            })
        }
    }
    
    func removeClass(atIndexPath indexPath: IndexPath) {
        let course_code = homeVC.courses[indexPath.row].code
        ServerService.removeClassesFromFirebase(withCourseCodes: [course_code])
        homeVC.courses.remove(at: indexPath.row)
        homeVC.tableView.deleteRows(at: [indexPath], with: .automatic)
        homeVC.toggleNoClassLabel()
        handleDismiss()
    }
    
    @objc func handleDismiss() {
        
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            
            self.view.alpha = 0
            
        }, completion: {_ in
            UIView.animate(withDuration: 0.3, delay: 1, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                
                self.dismiss(animated: true, completion: nil)
                
            }, completion: nil)
        })
    }
    
    @IBAction func copyButtonClicked(_ sender: Any) {
        UIPasteboard.general.string = "\(course.code)"
        animateIn()
    }
    
    @IBAction func exitClicked(_ sender: Any) {
        handleDismiss()
    }
    
    @IBAction func signUpClicked(_ sender: Any) {
        presentWebController()
    }
    
    @IBAction func removeClicked(_ sender: Any) {
        removeClass(atIndexPath: indexPath)
    }
}
