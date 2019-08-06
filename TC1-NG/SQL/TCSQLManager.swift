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
    
    static func getDBPath() -> String{
        NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentDirPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let fileManager = FileManager.default
        var isDir : ObjCBool = false
        let isExits = fileManager.fileExists(atPath: documentDirPath, isDirectory:&isDir)
        if isExits && !isDir.boolValue{
            fatalError("The dir is file，can not create dir.")
        }
        if !isExits {
            try! FileManager.default.createDirectory(atPath: documentDirPath, withIntermediateDirectories: true, attributes: nil)
            print("Create db dir success-\(documentDirPath)")
        }
        let dbPath = documentDirPath + "/TC.db"
        if !FileManager.default.fileExists(atPath: dbPath) {
            FileManager.default.createFile(atPath: dbPath, contents: nil, attributes: nil)
            print("Create db file success-\(dbPath)")
        }
        print(dbPath)
        return dbPath
    }
    
}
