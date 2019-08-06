//
//  URL+JSON.swift
//  TC1-NG
//
//  Created by cpu on 2019/8/5.
//  Copyright © 2019 TC1. All rights reserved.
//

import Foundation
import SwiftyJSON

extension URL{
    func requestJSON(_ callBack:@escaping (JSON)->Void){
        DispatchQueue.global().async {
            if let data = try? Data(contentsOf: self),let json = try? JSON(data: data){
                DispatchQueue.main.async {
                    callBack(json)
                }
            }
        }
    }
}
