//
//  TCDeviceCell.swift
//  TC1-NG
//
//  Created by QAQ on 2019/4/24.
//  Copyright © 2019 TC1. All rights reserved.
//

import UIKit

class TCDeviceCell: UITableViewCell {
    
    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var iconImage: UIImageView!
    @IBOutlet weak var deviceTitle: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.bgView.layer.masksToBounds = true
        self.bgView.layer.cornerRadius = 5
//        self.iconImage.image?.renderingMode = .alwaysTemplate
        self.iconImage.tintColor = #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
