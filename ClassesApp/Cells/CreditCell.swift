//
//  CreditCell.swift
//  ClassesApp
//
//  Created by Darrel Muonekwu on 4/21/20.
//  Copyright © 2020 Darrel Muonekwu. All rights reserved.
//

import UIKit

class CreditCell: UITableViewCell {

    @IBOutlet weak var iconImage: UIImageView!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
