//
//  A1Button.swift
//  TC1-NG
//
//  Created by cpu on 2019/8/5.
//  Copyright © 2019 TC1. All rights reserved.
//

import UIKit

class A1Button: UIButton {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.layoutButtonWithImageTitle()
    }
    
    private func layoutButtonWithImageTitle(){
        guard let imageWith = self.imageView?.image?.size.width else { return}
        guard let imageHeight = self.imageView?.image?.size.height else { return}
        guard let labelWidth = self.titleLabel?.intrinsicContentSize.width else { return}
        guard let labelHeight = self.titleLabel?.intrinsicContentSize.height else { return}
        let imageEdgeInsets = UIEdgeInsets(top: -labelHeight-8/2.0, left: 0, bottom: 0, right: -labelWidth);
        let labelEdgeInsets = UIEdgeInsets(top: 0, left: -imageWith, bottom: -imageHeight-8/2.0, right: 0);
        self.titleEdgeInsets = labelEdgeInsets
        self.imageEdgeInsets = imageEdgeInsets
    }
    
}
