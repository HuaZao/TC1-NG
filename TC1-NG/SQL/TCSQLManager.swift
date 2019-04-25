//
//  TCSQLManager.swift
//  TC1-NG
//
//  Created by QAQ on 2019/4/24.
//  Copyright © 2019 TC1. All rights reserved.
//

import UIKit
import LKDBHelper

//class SocketModel:NSObject{
//    var title = String()
//    var socketId = 1
//    var isOn = 0
//
//    override static func getPrimaryKey() -> String {
//        return "socketId"
//    }
//
//    override static func getUsingLKDBHelper() -> LKDBHelper {
//        return LKDBHelper(dbPath: TCSQLManager.getDBPath())
//    }
//
//}
//
//class TCDeviceModel:NSObject{
//    //当前设备名称
//    var name = String()
//    //设备类型编号,1表示zTC1排插
//    let type = 1
//    //设备类型名称
//    var type_name = "zTC1"
//    //当前设备的mac地址
//    var mac = String()
//    //各个插座的数据
//    var sockets = [SocketModel]()
//
//    override static func getPrimaryKey() -> String {
//        return "mac"
//    }
//
//    override static func getUsingLKDBHelper() -> LKDBHelper {
//        return LKDBHelper(dbPath: TCSQLManager.getDBPath())
//    }
//
//}

class TCSQLManager: NSObject {
    
    static func addTCDevice(_ model:TCDeviceModel){
        model.saveToDB()
    }
    
    static func removeTCDevice(_ model:TCDeviceModel){
        model.deleteToDB()
    }
    
    static  func queryAllTCDevice()-> [TCDeviceModel]?{
        if let objects = TCDeviceModel.search(withWhere: nil, orderBy: nil, offset: 0, count: 0) as? [TCDeviceModel]{
            return objects
        }
        return nil
    }
    
    static func updateTCDevice(_ model:TCDeviceModel){
        model.updateToDB()
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
