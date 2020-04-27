//
//  HistoryController.swift
//  ClassesApp
//
//  Created by Darrel Muonekwu on 4/24/20.
//  Copyright © 2020 Darrel Muonekwu. All rights reserved.
//

import UIKit

class HistoryController: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var containerView: RoundedView!
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var tableView: UITableView!
    
    var presentPurchaseHist: Bool! // purchase history or tracking history

    var noClassLabel: UILabel!
    var labelHasBeenPresented: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if presentPurchaseHist {
            titleLabel.text = "Purchase History"
        }
        else {
            titleLabel.text = "Tracked Classes History"
        }
        
        addLabel()
        animateViewDownward()
        setUpGestures()
        setUpTableView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateViewUpwards()
    }
    
    func setUpTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        toggleNoClassLabel()
    }
    
    func setUpGestures() {
        backgroundView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleDismiss)))
        
        let swipe: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(handleDismiss))
        swipe.direction = .down
        backgroundView.addGestureRecognizer(swipe)
    }
    
    func animateViewUpwards() {
        guard let window = UIApplication.shared.keyWindow else { return }
        
        let height: CGFloat = 600
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
    
    func addLabel() {
        guard let window = UIApplication.shared.keyWindow else { print("not window"); return }

        noClassLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 250, height: 350))
        noClassLabel.font = UIFont(name: "Futura", size: 20.0)
        noClassLabel.center = window.center
        noClassLabel.textAlignment = .center
        noClassLabel.text = "No new notifications. Check in again later or pull down to refresh!"
        noClassLabel.numberOfLines = 0
        
        noClassLabel.center = self.view.center
        noClassLabel.center.x = self.view.center.x
        noClassLabel.center.y = self.view.center.y
        
        labelHasBeenPresented = true

        if presentPurchaseHist {
            noClassLabel.text = "No purchase history. Your purchase history will appear when you get credits at the Store!"
        }
        else {
            noClassLabel.text = "No classes yet. Once you being tracking your first classes, they will appear here!"
        }
        
        self.view.addSubview(noClassLabel)
    }
    
    func toggleNoClassLabel(){
        if presentPurchaseHist {
            if UserService.user.purchaseHistory.count > 0  {
                self.noClassLabel.isHidden = true
            }
        }
        else {
            if UserService.user.trackedClassesArr.count > 0  {
                self.noClassLabel.isHidden = true
            }
        }
    }
    
    @objc func handleDismiss() {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            
            self.backgroundView.alpha = 0
            
        }, completion: {_ in
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                
                self.dismiss(animated: true, completion: nil)
                
            }, completion: nil)
        })
    }
}

extension HistoryController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if presentPurchaseHist {
            return UserService.user.purchaseHistory.count
        }
        
        return UserService.user.trackedClassesArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.row
        
        if presentPurchaseHist{
            let cell = tableView.dequeueReusableCell(withIdentifier: "PurchaseHistoryCell") as! PurchaseHistoryCell
            let purchase = UserService.user.purchaseHistory.reversed()[row]
            
            if purchase[DataBase.num_credits] == "1" {
                cell.numCreditsLabel.text = "\(purchase[DataBase.num_credits] ?? "Error") Credit"
            }
            else {
                cell.numCreditsLabel.text = "\(purchase[DataBase.num_credits] ?? "Error") Credits"
            }
            cell.timeLabel.text = purchase[DataBase.date]?.toDate().toStringInWords()
            cell.priceLabel.text = Int(purchase[DataBase.price] ?? "Error")?.penniesToFormattedDollars()
            return cell
        }
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsLabelCell") as! SettingsLabelCell
            let trackedClass = UserService.user.trackedClasses.reversed()[row]
            
            cell.titleLabel.text = "\(trackedClass[DataBase.course_code] ?? "Error")"
            cell.infoLabel.text = trackedClass[DataBase.date]?.toDate().toStringInWords()
            cell.infoLabel.font = cell.infoLabel.font.withSize(13) // set font size to 13
            return cell
        }
    }
}
