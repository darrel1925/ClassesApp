//
//  AutoEnrollController.swift
//  ClassesApp
//
//  Created by Darrel Muonekwu on 7/2/20.
//  Copyright © 2020 Darrel Muonekwu. All rights reserved.
//

import UIKit

class AutoEnrollController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpTableView()
    }
    
    func setUpTableView() {
        tableView.delegate = self
        tableView.dataSource = self 
    }
}

extension  AutoEnrollController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }
    
    
    
}
