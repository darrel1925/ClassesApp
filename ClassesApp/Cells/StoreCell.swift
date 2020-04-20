//
//  StoreCell.swift
//  ClassesApp
//
//  Created by Darrel Muonekwu on 4/14/20.
//  Copyright © 2020 Darrel Muonekwu. All rights reserved.
//

import UIKit

protocol StoreCellDelegate {
    func didTapGetCredits(row: Int?)
}

class StoreCell: UITableViewCell {

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var getCreditsLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var purchaseButton: RoundedButton!
    
    var delegate: StoreCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    
        // Configure the view for the selected state
    }

    @IBAction func getCreditsTapped(_ sender: Any) {
        delegate?.didTapGetCredits(row: getRow())
    }
    
    func getRow() -> Int? {
        guard let superView = self.superview as? UITableView else {
            return nil
        }
        let row = superView.indexPath(for: self)?.row
        return row
    }
}
