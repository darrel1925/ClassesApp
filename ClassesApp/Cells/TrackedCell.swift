//
//  TrackedCell.swift
//  ClassesApp
//
//  Created by Darrel Muonekwu on 3/29/20.
//  Copyright © 2020 Darrel Muonekwu. All rights reserved.
//

import UIKit

class TrackedCell: UITableViewCell {

    @IBOutlet weak var courseCodeLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var cellBackgroundView: TrackedCell!
    @IBOutlet weak var cellView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
