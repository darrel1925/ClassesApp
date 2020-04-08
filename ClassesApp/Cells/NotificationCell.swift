//
//  NotificationCell.swift
//  ClassesApp
//
//  Created by Darrel Muonekwu on 4/6/20.
//  Copyright © 2020 Darrel Muonekwu. All rights reserved.
//

import UIKit

class NotificationCell: UITableViewCell {

    @IBOutlet weak var conatinerView: UIView!
    @IBOutlet weak var courseNumberLabel: UILabel!
    @IBOutlet weak var courseDescriptionLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()

        conatinerView.layer.cornerRadius = 5
        conatinerView.layer.shadowColor = UIColor.black.cgColor
        conatinerView.layer.shadowOpacity = 0.4
        conatinerView.layer.shadowOffset = CGSize.zero
        conatinerView.layer.shadowRadius = 2

    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
