//
//  TCSQLManager.swift
//  TC1-NG
//
//  Created by QAQ on 2019/4/24.
//  Copyright © 2019 TC1. All rights reserved.
//

import UIKit
import LKDBHelper


class TCSQLManager: NSObject {
    
    static func addTCDevice(_ model:TCDeviceModel){
        model.saveToDB()
    }
    
    static func removeTCDevice(_ model:TCDeviceModel){
        model.deleteToDB()
    }
    
    static  func queryAllTCDevice()-> [TCDeviceModel]{
        if let objects = TCDeviceModel.search(withWhere: nil, orderBy: nil, offset: 0, count: 0) as? [TCDeviceModel]{
            return objects
        }
        return [TCDeviceModel]()
    }
    
    static func updateTCDevice(_ model:TCDeviceModel){
        DispatchQueue.global().async {
            model.updateToDB()
        }
    }
    
    static func deciveisExist(_ mac:String)->Bool{
        let all = self.queryAllTCDevice()
        return all.contains(where: {$0.mac == mac})
    }
    
    static func queryDevice(_ mac:String) ->TCDeviceModel?{
        if let object = TCDeviceModel.searchSingle(withWhere: "mac = '\(mac)'", orderBy: nil) as? TCDeviceModel{
            return object
        }else{
            return nil
        }
    }
    
    
    
}
