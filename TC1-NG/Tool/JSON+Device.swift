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
    func addDevice()->TCDeviceModel?{
        let model = TCDeviceModel()
        model.name = self["name"].stringValue
        model.mac = self["mac"].stringValue
        model.ip = self["ip"].stringValue
        if TCSQLManager.deciveisExist(model.mac){
            return nil
        }
        model.type_name = self["type_name"].stringValue
        if let deviceType = FXDeviceType(rawValue: self["type"].uIntValue){
            model.type = deviceType
            if deviceType == .TC1{
                model.sockets = [SocketModel]()
                for i in 1...6{
                    let socket = SocketModel()
                    socket.isOn = false
                    socket.socketId = model.mac + "_\(i)"
                    socket.sockeTitle = "插座\(i)"
                    socket.canEdit = true
                    model.sockets.append(socket)
                }
            }else if deviceType == .DC1{
                model.sockets = [SocketModel]()
                for i in 1...4{
                    let socket = SocketModel()
                    socket.isOn = false
                    socket.socketId = model.mac + "_\(i)"
                    if i == 0{
                        socket.canEdit = false
                        socket.sockeTitle = "总开关"
                    }else{
                        socket.canEdit = true
                        socket.sockeTitle = "插座\(i)"
                    }
                    model.sockets.append(socket)
                }
            }
        }else{
            //默认TC1
           model.type = .TC1
        }
        if let mqtt_uri = self["mqtt_uri"].string{
            model.host = mqtt_uri
        }
        if let mqtt_port = self["mqtt_port"].int{
            model.port = mqtt_port
        }
        if let mqtt_user = self["mqtt_user"].string{
            model.username = mqtt_user
        }
        if let mqtt_password = self["mqtt_password"].string{
            model.password = mqtt_password
        }
        TCSQLManager.addTCDevice(model)
        print("MAC:\(model.mac) 设备\(model.type_name)已经添加到本地")
        return model
    }
    
    func isActivate()->Bool{
        return self["lock"].string == "false"
    }
}
