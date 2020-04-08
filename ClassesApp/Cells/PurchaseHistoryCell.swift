//
//  PurchaseHistoryCell.swift
//  ClassesApp
//
//  Created by Darrel Muonekwu on 4/7/20.
//  Copyright © 2020 Darrel Muonekwu. All rights reserved.
//

import UIKit

class PurchaseHistoryCell: UITableViewCell {

    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var courseTitleCell: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
