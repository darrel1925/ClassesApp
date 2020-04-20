//
//  StoreController.swift
//  ClassesApp
//
//  Created by Darrel Muonekwu on 4/14/20.
//  Copyright © 2020 Darrel Muonekwu. All rights reserved.
//

import UIKit
import Stripe
import FirebaseFunctions
import FirebaseFirestore


class StoreController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var creditsLabel: UILabel!
    @IBOutlet weak var backgroundView: RoundedView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.prefersLargeTitles = true        
        setUpTableView()
        setUpGestures()
        setCreditsLabel()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setCreditsLabel()
    }
    
    func setUpTableView() {
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    func setCreditsLabel() {
        if UserService.user.credits == 0 {
         creditsLabel.text = "You have \(UserService.user.credits) Credits."
        }
        else if UserService.user.credits == 1 {
            creditsLabel.text = "You have \(UserService.user.credits) Credit!"
        }
        else {
            creditsLabel.text = "You have \(UserService.user.credits) Credits!"
        }
    }
    
    func setUpGestures() {
        let swipe1: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(self.handleDismiss))
        let swipe2: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(self.handleDismiss))
        swipe1.direction = .down
        swipe2.direction = .down
        backgroundView.addGestureRecognizer(swipe1)
        navigationController?.navigationBar.addGestureRecognizer(swipe2)
    }
    
    func presentStorePopUpVC(row: Int) {
        let storePopUpVC = StorePopUpController()
        storePopUpVC.modalPresentationStyle = .overFullScreen
        storePopUpVC.storeController = self
        switch row {
        case 0:
            storePopUpVC.purchasingCredits = 1
        case 1:
            storePopUpVC.purchasingCredits = 3
        case 2:
            storePopUpVC.purchasingCredits = 10
        default:
            return
        }
        self.present(storePopUpVC, animated: true, completion: nil)
    }
    
    @objc func handleDismiss() {
        dismiss(animated: true, completion: nil )
    }
    
    @IBAction func exitButtonClicked(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}

extension StoreController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.row
        let cell = tableView.dequeueReusableCell(withIdentifier: "StoreCell") as! StoreCell
        cell.delegate = self
        cell.containerView.layer.cornerRadius = 10
        cell.purchaseButton.layer.cornerRadius = 10
        
        switch row {
        case 0:
            cell.getCreditsLabel.text = "Get 1 Credit"
            cell.priceLabel.text = AppConstants.price_map["1"]?.penniesToFormattedDollars()
            cell.purchaseButton.setTitle("Get Credit", for: .normal)
            return cell
        case 1:
            cell.getCreditsLabel.text = "Get 3 Credits"
            cell.priceLabel.text = AppConstants.price_map["3"]?.penniesToFormattedDollars()
            return cell
        case 2:
            cell.getCreditsLabel.text = "Get 10 Credits"
            cell.priceLabel.text = AppConstants.price_map["10"]?.penniesToFormattedDollars()
            return cell
        default:
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = indexPath.row
        presentStorePopUpVC(row: row)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 95
    }
}

extension StoreController: StoreCellDelegate {
    func didTapGetCredits(row: Int?) {
        if let row = row {
            self.presentStorePopUpVC(row: row)
        }
    }
}
