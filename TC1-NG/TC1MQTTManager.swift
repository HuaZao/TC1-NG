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
    weak var delegate:TC1MQTTManagerDelegate?
    
    func connectTC1UdpService(){
//        self.messageBlock = message
//        //全网发送UDP配对
//        let udpSocket = GCDAsyncUdpSocket(delegate: self, delegateQueue: DispatchQueue.global())
//        do {
//            try udpSocket.enableBroadcast(true)
//            try udpSocket.bind(toPort: 10181)
//            try udpSocket.beginReceiving()
////            udpSocket.send(self.getJSONStringFromDictionary(dictionary: ["cmd":"device report"]), toHost: "192.168.50.255", port: 10182, withTimeout: 20, tag: 1)
//        } catch  {
//            print("UDP Error\(error.localizedDescription)")
//        }
    }
    
    func initTC1MQTTService(){
         let mqttConfig = MQTTConfig(clientId: "clientId", host: "home.wula.vip", port: 1883, keepAlive: 60)
        mqttConfig.mqttAuthOpts = MQTTAuthOpts(username: "WuLa", password: "23333333")
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
    
    func subscribeDeviceMessage(mac:String,qos:Int = 0){
        self.mqttClient?.subscribe("device/ztc1/" + mac  + "/state", qos: Int32(qos))
    }
    
    func unSubscribeDeviceMessage(mac:String){
        self.mqttClient?.unsubscribe("device/ztc1/" + mac  + "/state")
    }
    
    func sendDeviceReportCmd(){
        //QOS为2,确保扫描出全部设备而且消息不重复!
        self.mqttClient?.publish(string: "{\"cmd\":\"device report\"}", topic: "device/ztc1/set", qos: Int32(2), retain: true)
    }
    
    func getDeviceFullState(name:String,mac:String){
        let cmd = "{\"name\":\"\(name)\",\"mac\":\"\(mac)\",\"version\":null,\"setting\":{\"mqtt_uri\":null,\"mqtt_port\":null,\"mqtt_user\":null,\"mqtt_password\":null}}"
        self.mqttClient?.publish(string:cmd, topic: "device/ztc1/set", qos: Int32(1), retain: true)
    }
    
}

extension TC1MQTTManager:GCDAsyncUdpSocketDelegate{
    
    
    //UDP
    func udpSocket(_ sock: GCDAsyncUdpSocket, didSendDataWithTag tag: Int) {
        print("Tag为\(tag) 已发送!")
    }
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didNotConnect error: Error?) {
        print("1!")
    }
    
    func udpSocketDidClose(_ sock: GCDAsyncUdpSocket, withError error: Error?) {
        print("close")
    }
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didConnectToAddress address: Data) {
        print("c")
    }
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didNotSendDataWithTag tag: Int, dueToError error: Error?) {
        print("Tag为\(tag) 发送失败! ERROR-> \(String(describing: error?.localizedDescription))")
    }
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?) {
//        let ip = GCDAsyncUdpSocket.host(fromAddress: address)
//        let port = GCDAsyncUdpSocket.port(fromAddress: address)
//        print("收到回应-----> IP:\(String(describing: ip)) Port:\(port)")
//        if let str = String(data: data, encoding: String.Encoding.utf8){
//        DispatchQueue.main.async {
//            self.messageBlock!(data)
//        }
//            print("接送到的字符串-> \(str)")
//        }
    }
    
}
