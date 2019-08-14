//
//  APIServiceManager.swift
//  TC1-NG
//
//  Created by 花早 on 2019/5/12.
//  Copyright © 2019 TC1. All rights reserved.
//

import UIKit
import CocoaAsyncSocket
import MQTTClient
import SwiftyJSON
import RealReachability
import PKHUD

protocol APIServiceReceiveDelegate:class {
    func DeviceServiceOnConnect()
    func DeviceServiceDidDisconnect(error:Error?)
    func DeviceServiceReceivedMessage(message:Data)
    //MQTT Only
    func DeviceServiceSubscribe(topics: [String])
    func DeviceServiceUnSubscribe(topic: String)
    func DeviceServicePublish(messageId: Int)
}

extension APIServiceReceiveDelegate{
    func DeviceServiceOnConnect(){
        
    }
    func DeviceServiceDidDisconnect(error:Error?){
        
    }
    func DeviceServiceSubscribe(topics: [String]){
        
    }
    func DeviceServiceUnSubscribe(topic: String){
        
    }
    func DeviceServicePublish(messageId: Int){
        
    }
}

class APIServiceManager: NSObject {
    
    static let share = APIServiceManager()
    private var mqttClient: MQTTSession?
    private var udpSocket:GCDAsyncUdpSocket?
    private(set) var isLocal = false
    private(set) var isConnect = false
    private(set) var deviceModel:TCDeviceModel!
    weak var delegate:APIServiceReceiveDelegate?
    
    //用于发现设备
    func connectUDPService(){
        self.initTC1UDPService()
    }
    
    //用于连接设备
    func connectService(device:TCDeviceModel,ip:String? = nil){
        self.deviceModel = device
        if device.isOnline == true{
            print("当前强制MQTT环境")
            self.initDeviceMQTTService(device: device)
            return
        }
        self.isLan(ip: ip) { [unowned self] (isLocal) in
            if isLocal{
                print("当前为局域网环境")
                self.initTC1UDPService()
            }else{
                print("当前为外网环境")
                self.initDeviceMQTTService(device: device)
            }
        }
    }
    
    func closeService(){
        print("close service")
        self.mqttClient?.disconnect()
        self.udpSocket?.close()
    }
    
    
    private func initDeviceMQTTService(device:TCDeviceModel){
        guard device.host != "" else {
            HUD.flash(HUDContentType.labeledError(title: "错误", subtitle: "未配置MQTT服务器,切换到UDP"), delay: 3.0)
            self.initTC1UDPService()
            return
        }
        guard device.port > 0 else {
            HUD.flash(HUDContentType.labeledError(title: "错误", subtitle: "未配置MQTT服务器,切换到UDP"), delay: 3.0)
            self.initTC1UDPService()
            return
        }
        self.isLocal = false
        let transport = MQTTCFSocketTransport()
        transport.host = device.host
        transport.port = UInt32(device.port)
        self.mqttClient = MQTTSession()
        self.mqttClient?.transport = transport
        self.mqttClient?.userName = device.username
        self.mqttClient?.password = device.password
//        self.mqttClient?.clientId = device.type_name + device.mac
        self.mqttClient?.delegate = self
        MQTTLog.setLogLevel(.error)
        self.mqttClient?.connect(connectHandler: { (error) in
            if error != nil{
                HUD.flash(HUDContentType.labeledError(title: "连接失败", subtitle: error!.localizedDescription), delay: 5.0)
                print("MQTT服务器连接失败 ERROR \(error!.localizedDescription)")
            }else{
                self.delegate?.DeviceServiceOnConnect()
            }
        })
        self.mqttClient?.close(disconnectHandler: { (error) in
            self.delegate?.DeviceServiceDidDisconnect(error: error)
        })
        self.mqttClient?.connect()
    }
    
    private func initTC1UDPService(){
        self.isLocal = true
        self.udpSocket = GCDAsyncUdpSocket(delegate: self, delegateQueue: DispatchQueue.global())
        do {
            try self.udpSocket?.enableBroadcast(true)
            try self.udpSocket?.bind(toPort: 10181)
            try self.udpSocket?.beginReceiving()
            //UDP只是接受数据用,所以不会触发连接成功的代理
            self.delegate?.DeviceServiceOnConnect()
        } catch  {
            print("UDP Error\(error.localizedDescription)")
        }
    }
    
    //    判断是否在同一个局域网,IP为空则默认为UDP通讯!
    private func isLan(ip:String?,_ realReachabilitySatas:@escaping (Bool)->Void){
        if let ip = ip{
            //这里先用ping判断,不太严谨凑合用
            let pingHelper = PingHelper()
            pingHelper.host = ip
            pingHelper.timeout = 1
            pingHelper.ping { (isReach) in
                realReachabilitySatas(isReach)
            }
        }else{
            realReachabilitySatas(true)
        }
    }
    
}

extension APIServiceManager{
    func subscribeDeviceMessage(qos:Int = 0){
        var topic = String()
        switch self.deviceModel.type {
        case .TC1:
            topic = "device/ztc1/" + self.deviceModel.mac + "/state"
        case .DC1:
            topic = "device/zdc1/" + self.deviceModel.mac + "/state"
        case .A1:
            topic = "device/za1/" + self.deviceModel.mac + "/state"
        }
        self.mqttClient?.subscribe(toTopic: topic, at: MQTTQosLevel.init(rawValue: UInt8(qos))!, subscribeHandler: { (error, tops) in
            self.delegate?.DeviceServiceSubscribe(topics:[topic])
        })
    }
    
    func unSubscribeDeviceMessage(){
        var topic = String()
        switch self.deviceModel.type {
        case .TC1:
            topic = "device/ztc1/" + self.deviceModel.mac + "/state"
        case .DC1:
            topic = "device/zdc1/" + self.deviceModel.mac + "/state"
        case .A1:
            topic = "device/za1/" + self.deviceModel.mac + "/state"
        }
        self.mqttClient?.unsubscribeTopic(topic, unsubscribeHandler: { (error) in
            self.delegate?.DeviceServiceUnSubscribe(topic: topic)
        })
    }
    
    
    func publishMessage(_ message:[String:Any],qos:Int = 0){
        if let jsonString = JSON(message).rawString(.utf8, options: .init(rawValue: 0)){
            if self.isLocal{
                self.udpSocket?.send(jsonString.data(using: String.Encoding.utf8)!, toHost: "255.255.255.255", port: 10182, withTimeout: 60, tag: Int.random(in: 1...100))
                print("publishMessage With UDP -> \(jsonString)")
            }else{
                if self.isConnect{
                    var topic = String()
                    switch self.deviceModel.type {
                    case .TC1:
                        topic = "device/ztc1/set"
                    case .DC1:
                        topic = "device/zdc1/set"
                    case .A1:
                        topic = "device/za1/" + self.deviceModel.mac + "/set"
                    }
                    self.mqttClient?.publishData(jsonString.data(using: .utf8)!, onTopic: topic, retain: true, qos: MQTTQosLevel.init(rawValue: UInt8(qos))!,publishHandler:{ (error) in
                        self.delegate?.DeviceServicePublish(messageId: 0)
                    })
                    print("publishMessage With MQTT -> \(jsonString)")
                }
            }
            
        }
    }
    
    func activateDevice(lock:String){
        let cmd = ["mac":self.deviceModel.mac,"lock":lock]
        self.publishMessage(cmd,qos: 1)
    }
    
    func switchTC1Device(state:Bool,index:Int){
        var cmd = [String:Any]()
        if state{
            cmd = ["mac":self.deviceModel.mac,"plug_\(index)":["on":1]] as [String : Any]
        }else{
            cmd = ["mac":self.deviceModel.mac,"plug_\(index)":["on":0]] as [String : Any]
        }
        self.publishMessage(cmd,qos: 1)
    }
    
    func queryTask(index:Int){
        let cmd = ["mac":self.deviceModel.mac,
                   "plug_\(index)":[
                    "name":nil,
                    "setting":[
                        "task_0":nil,
                        "task_1":nil,
                        "task_2":nil,
                        "task_3":nil,
                        "task_4":nil
                    ]
            ]
            ] as [String : Any]
        self.publishMessage(cmd,qos: 1)
    }
    
    func taskDevice(task:TCTask,index:Int,taskIndex:Int){
        let cmd = ["mac":self.deviceModel.mac,
                   "plug_\(index)":[
                    "setting":[
                        "task_\(taskIndex)":[
                            "hour":task.hour,
                            "minute":task.minute,
                            "repeat":task.repeat,
                            "action":task.action,
                            "on":task.on
                        ]
                    ]
            ]
            ] as [String : Any]
        self.publishMessage(cmd,qos: 1)
    }
    
    func isDeviceActivate(){
        let cmd2 = ["mac":self.deviceModel.mac,"lock":nil]
        self.publishMessage(cmd2 as [String : Any],qos: 2)
    }
    
    func sendDeviceReportCmd(){
        let cmd = ["cmd":"device report"]
        self.publishMessage(cmd,qos: 2)
    }
    
    func getDeviceFullState(){
        var cmd = [String:Any?]()
        switch self.deviceModel.type {
        case .TC1:
            cmd = ["name":nil,"mac":self.deviceModel.mac,"version":nil,"power":nil,
                   "setting":["mqtt_uri":nil,"mqtt_port":nil,"mqtt_user":nil,"mqtt_password":nil],
                   "plug_0":["setting":["name":nil]],
                   "plug_1":["setting":["name":nil]],
                   "plug_2":["setting":["name":nil]],
                   "plug_3":["setting":["name":nil]],
                   "plug_4":["setting":["name":nil]],
                   "plug_5":["setting":["name":nil]]
            ]
        case .DC1:
            cmd = ["name":nil,"mac":self.deviceModel.mac,"version":nil,"power":nil,"voltage":nil,"current":nil,
                   "setting":["mqtt_uri":nil,"mqtt_port":nil,"mqtt_user":nil,"mqtt_password":nil],
                   "plug_0":["setting":["name":nil]],
                   "plug_1":["setting":["name":nil]],
                   "plug_2":["setting":["name":nil]],
                   "plug_3":["setting":["name":nil]]
            ]
        case .A1:
            cmd = ["name":nil,"mac":self.deviceModel.mac,"version":nil,"on":nil,"speed":nil,
                   "setting":["mqtt_uri":nil,"mqtt_port":nil,"mqtt_user":nil,"mqtt_password":nil]
            ]
        }
        self.publishMessage(cmd as [String : Any],qos: 1)
        self.sendDeviceReportCmd()
    }
}

extension APIServiceManager:MQTTSessionDelegate{
    
    func connected(_ session: MQTTSession!) {
        self.isConnect = true
        self.delegate?.DeviceServiceOnConnect()
    }
    
    func newMessage(_ session: MQTTSession!, data: Data!, onTopic topic: String!, qos: MQTTQosLevel, retained: Bool, mid: UInt32) {
        if data.count == 0 {
            return
        }
        self.delegate?.DeviceServiceReceivedMessage(message: data)
    }
    
    func subAckReceived(_ session: MQTTSession!, msgID: UInt16, grantedQoss qoss: [NSNumber]!) {
        
    }
    
    func unsubAckReceived(_ session: MQTTSession!, msgID: UInt16) {
        
    }
    
    func connectionError(_ session: MQTTSession!, error: Error!) {
        self.isConnect = false
        self.delegate?.DeviceServiceDidDisconnect(error: error)
    }
    
    func connectionClosed(_ session: MQTTSession!) {
        self.isConnect = false
        self.delegate?.DeviceServiceDidDisconnect(error: nil)
    }
    
    
}


extension APIServiceManager:GCDAsyncUdpSocketDelegate{
    
    //UDP
    func udpSocket(_ sock: GCDAsyncUdpSocket, didSendDataWithTag tag: Int) {
        self.delegate?.DeviceServicePublish(messageId: tag)
    }
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didNotConnect error: Error?) {
        self.delegate?.DeviceServiceDidDisconnect(error: error)
    }
    
    func udpSocketDidClose(_ sock: GCDAsyncUdpSocket, withError error: Error?) {
        self.delegate?.DeviceServiceDidDisconnect(error: error)
    }
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didConnectToAddress address: Data) {
        self.delegate?.DeviceServiceOnConnect()
    }
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didNotSendDataWithTag tag: Int, dueToError error: Error?) {
        print("Tag为\(tag) 发送失败! ERROR-> \(String(describing: error?.localizedDescription))")
    }
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?) {
        DispatchQueue.main.async {
            self.delegate?.DeviceServiceReceivedMessage(message:data)
        }
    }
    
}
