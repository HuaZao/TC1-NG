//
//  URL+JSON.swift
//  TC1-NG
//
//  Created by cpu on 2019/8/5.
//  Copyright © 2019 TC1. All rights reserved.
//

import Foundation
import SwiftyJSON
import Alamofire

extension URL{
    func requestJSON(params:[String:String],callBack:@escaping (JSON)->Void){
        Alamofire.request(self.absoluteString, method: .post, parameters: params).responseJSON { (response) in
            if response.result.isSuccess{
                callBack(JSON(response.result.value as Any))
            }
        }
    }
}
