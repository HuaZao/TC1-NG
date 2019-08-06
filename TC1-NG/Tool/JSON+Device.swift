//
//  JSON+Device.swift
//  TC1-NG
//
//  Created by cpu on 2019/8/5.
//  Copyright © 2019 TC1. All rights reserved.
//

import Foundation
import SwiftyJSON

extension JSON{
    func addDevice()->TCDeviceModel{
        let model = TCDeviceModel()
        model.name = self["name"].stringValue
        model.mac = self["mac"].stringValue
        model.ip = self["ip"].stringValue
        if let deviceType = FXDeviceType(rawValue: self["type"].uIntValue){
            model.type = deviceType
            if deviceType == .TC1{
                model.sockets = [SocketModel]()
                for i in 1...6{
                    let socket = SocketModel()
                    socket.isOn = false
                    socket.socketId = model.mac + "_\(i)"
                    socket.sockeTtitle = "插座\(i)"
                    model.sockets.append(socket)
                }
            }
            if deviceType == .DC1{
                model.sockets = [SocketModel]()
                for i in 1...4{
                    let socket = SocketModel()
                    socket.isOn = false
                    socket.socketId = model.mac + "_\(i)"
                    socket.sockeTtitle = "插座\(i)"
                    model.sockets.append(socket)
                }
            }
        }
        model.type_name = self["type_name"].stringValue
        TCSQLManager.addTCDevice(model)
        print("MAC:\(model.mac) 设备\(model.type_name)已经添加到本地")
        return model
    }
    
    func isA2633063Protocol()->Bool{
        return self["Protocol"].stringValue == "com.zyc.basic"
    }
    
    func isActivate()->Bool{
        return self["lock"].string == "false"
    }
}
