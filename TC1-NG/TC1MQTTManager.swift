//
//  TC1MQTTManager.swift
//  TC1-NG
//
//  Created by QAQ on 2019/4/19.
//  Copyright © 2019 TC1. All rights reserved.
//

import UIKit
import CocoaAsyncSocket
import Moscapsule
import SwiftyJSON

protocol TC1MQTTManagerDelegate:class {
    func TC1MQTTManagerOnConnect(code:Int)
    func TC1MQTTManagerDidConnect(code:Int)
    func TC1MQTTManagerReceivedMessage(message:Data)
    func TC1MQTTManagerSubscribe(messageId: Int,grantedQos: Array<Int32>)
    func TC1MQTTManagerUnSubscribe(messageId: Int)
    func TC1MQTTManagerPublish(messageId: Int)
}

extension TC1MQTTManagerDelegate{
    func TC1MQTTManagerOnConnect(code:Int){
        
    }
    func TC1MQTTManagerDidConnect(code:Int){
        
    }
    func TC1MQTTManagerSubscribe(messageId: Int,grantedQos: Array<Int32>){
        
    }
    func TC1MQTTManagerUnSubscribe(messageId: Int){
        
    }
    func TC1MQTTManagerPublish(messageId: Int){
        
    }
}

class TC1MQTTManager: NSObject {
    
    static let share = TC1MQTTManager()
    private var mqttClient: MQTTClient?
    var isUDP = true
    private var udpSocket:GCDAsyncUdpSocket?
    private var mac = String()
    weak var delegate:TC1MQTTManagerDelegate?
    
    func initTC1Service(_ service:MQTTModel? = nil,mac:String){
        //UDP广播的地址为255.255.255.255,局域网内的TC1都会发送响应,通过MAC判断是否返回给前端处理d0bae463c730
        self.mac = mac
        if let service = service{
            //初始化UDP和MQTT服务器
//            self.useMQTTService(service: service)
            self.useUDPService()
        }else{
            //没有设置MQTT服务器只初始化UDP
            self.useUDPService()
        }
    }
    
    private func useMQTTService(service:MQTTModel){
        self.isUDP = false
        self.mqttClient?.disconnect()
        let mqttConfig = MQTTConfig(clientId: service.clientId, host: service.host, port: Int32(service.port), keepAlive: 60)
        mqttConfig.mqttAuthOpts = MQTTAuthOpts(username:service.username, password:service.password)
        mqttConfig.onConnectCallback = {
            self.delegate?.TC1MQTTManagerOnConnect(code: $0.rawValue)
        }
        mqttConfig.onDisconnectCallback  = {
            self.delegate?.TC1MQTTManagerDidConnect(code: $0.rawValue)
        }
        mqttConfig.onMessageCallback = {
             self.delegate?.TC1MQTTManagerReceivedMessage(message: $0.payload ?? Data())
        }
        mqttConfig.onSubscribeCallback = {
            self.delegate?.TC1MQTTManagerSubscribe(messageId: $0, grantedQos: $1)
        }
        mqttConfig.onUnsubscribeCallback = {
            self.delegate?.TC1MQTTManagerUnSubscribe(messageId: $0)
        }
        mqttConfig.onPublishCallback = {
            self.delegate?.TC1MQTTManagerPublish(messageId: $0)
        }
        self.mqttClient = MQTT.newConnection(mqttConfig)
    }
    
    private func useUDPService(){
        self.isUDP = true
        self.udpSocket?.close()
        if self.udpSocket == nil {
            self.udpSocket = GCDAsyncUdpSocket(delegate: self, delegateQueue: DispatchQueue.global())
        }
        do {
            try self.udpSocket?.enableBroadcast(true)
            try self.udpSocket?.bind(toPort: 10181)
            try self.udpSocket?.beginReceiving()
            self.sendDeviceReportCmd()
        } catch  {
            print("UDP Error\(error.localizedDescription)")
        }
    }
    
    func subscribeDeviceMessage(mac:String,qos:Int = 0){
        if self.isUDP{
            return;
        }
        self.mqttClient?.subscribe("device/ztc1/" + mac  + "/state", qos: Int32(qos))
    }
    
    func unSubscribeDeviceMessage(mac:String){
        if self.isUDP{
            return
        }
        self.mqttClient?.unsubscribe("device/ztc1/" + mac  + "/state")
    }
    
    
    func publishMessage(_ message:[String:Any],qos:Int = 0){
        if let jsonString = JSON(message).rawString(.utf8, options: .init(rawValue: 0)){
            print("publishMessage String -> \(jsonString)")
            if self.isUDP{
                self.udpSocket?.send(jsonString.data(using: String.Encoding.utf8)!, toHost: "255.255.255.255", port: 10182, withTimeout: 60, tag: Int.random(in: 1...100))
            }else{
                self.mqttClient?.publish(string:jsonString, topic: "device/ztc1/set", qos: Int32(qos), retain: true)
            }
        }
    }
    
    func switchDevice(state:Bool,index:Int,mac:String){
        var cmd = [String:Any]()
        if state{
            cmd = ["mac":mac,"plug_\(index)":["on":1]] as [String : Any]
        }else{
            cmd = ["mac":mac,"plug_\(index)":["on":0]] as [String : Any]
        }
        self.publishMessage(cmd,qos: 1)
    }
    
    func queryTask(index:Int){
        let cmd = ["mac":self.mac,
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
        let cmd = ["mac":self.mac,
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
    
    func sendDeviceReportCmd(){
        let cmd = ["cmd":"device report"]
        self.publishMessage(cmd,qos: 2)
    }
    
    func getDeviceFullState(name:String,mac:String){
        let cmd = ["name":name,"mac":mac,"version":nil,"setting":["mqtt_uri":nil,"mqtt_port":nil,"mqtt_user":nil,"mqtt_password":nil]] as [String : Any?]
        self.publishMessage(cmd as [String : Any],qos: 1)
    }
    
}

extension TC1MQTTManager:GCDAsyncUdpSocketDelegate{
    
    
    //UDP
    func udpSocket(_ sock: GCDAsyncUdpSocket, didSendDataWithTag tag: Int) {
        self.delegate?.TC1MQTTManagerPublish(messageId: tag)
    }
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didNotConnect error: Error?) {
        self.delegate?.TC1MQTTManagerDidConnect(code: 0)
    }
    
    func udpSocketDidClose(_ sock: GCDAsyncUdpSocket, withError error: Error?) {
        self.delegate?.TC1MQTTManagerDidConnect(code: 0)
    }
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didConnectToAddress address: Data) {
        self.delegate?.TC1MQTTManagerOnConnect(code: 0)
    }
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didNotSendDataWithTag tag: Int, dueToError error: Error?) {
        print("Tag为\(tag) 发送失败! ERROR-> \(String(describing: error?.localizedDescription))")
    }
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?) {
        DispatchQueue.main.async {
            self.delegate?.TC1MQTTManagerReceivedMessage(message:data)
        }
    }
    
}
