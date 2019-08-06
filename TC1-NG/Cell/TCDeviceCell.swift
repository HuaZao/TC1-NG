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
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func loadDeviceModel(_ model:TCDeviceModel){
        self.deviceTitle?.text = model.name
        switch model.type{
        case .TC1:
            self.iconImage.image = #imageLiteral(resourceName: "icon_plug_highlight")
        case .DC1:
            self.iconImage.image = #imageLiteral(resourceName: "DC1")
        case .A1:
            self.iconImage.image = #imageLiteral(resourceName: "addCleaner")
        }
    }
    

}
