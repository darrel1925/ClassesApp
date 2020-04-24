//
//  CreditsController.swift
//  ClassesApp
//
//  Created by Darrel Muonekwu on 4/21/20.
//  Copyright © 2020 Darrel Muonekwu. All rights reserved.
//

import UIKit

class CreditsController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
  
    var iconDict : [[String: String]] = [
        [ "author" : "Freepik",
          "iconName": "information" ],
        [ "author" : "Pixel perfect",
          "iconName": "list" ],
        [ "author" : "Those Icons",
          "iconName": "logout" ],
        [ "author" : "Those Icons",
          "iconName": "menu" ],
        [ "author" : "Those Icons",
          "iconName": "notification" ],
        [ "author" : "Freepik",
          "iconName": "settings" ],
        [ "author" : "Kiranshastry",
          "iconName": "support" ],
        [ "author" : "Pixel perfect",
          "iconName": "swipe" ],
        [ "author" : "SmashIcons",
          "iconName": "message" ],
        [ "author" : "Freepik",
          "iconName": "speed" ],
        [ "author" : "Alfredo Hernandez",
          "iconName": "x" ],
    ]
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.prefersLargeTitles = true
        setUpTableView()
        setUpGestures()
    }

    func setUpTableView() {
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    func setUpGestures() {
        let swipe1: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(self.handleDismiss))
        swipe1.direction = .down
        navigationController?.navigationBar.addGestureRecognizer(swipe1)
    }
    
    @objc func handleDismiss() {
       dismiss(animated: true, completion: nil)
    }
    
    @IBAction func exitClicked(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}

extension CreditsController: UITableViewDelegate, UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        iconDict.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.row
        let cell = tableView.dequeueReusableCell(withIdentifier: "CreditCell") as! CreditCell
        
        let image = UIImage(named:iconDict[row]["iconName"]!)!
        let author = iconDict[row]["author"]
        
        cell.descriptionLabel.text = "Icon made by \(author ?? "") from www.flaticon.com"
        cell.iconImage.image = image
        return cell
    }
    
}
