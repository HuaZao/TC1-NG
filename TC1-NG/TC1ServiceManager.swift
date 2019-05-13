//
//  TC1ServiceManager.swift
//  TC1-NG
//
//  Created by 花早 on 2019/5/12.
//  Copyright © 2019 TC1. All rights reserved.
//

import UIKit
import CocoaAsyncSocket
import CocoaMQTT
import SwiftyJSON
import RealReachability
import PKHUD

protocol TC1ServiceReceiveDelegate:class {
    func TC1ServiceOnConnect()
    func TC1ServiceDidDisconnect(error:Error?)
    func TC1ServiceReceivedMessage(message:Data)
    //MQTT Only
    func TC1ServiceSubscribe(topic: String)
    func TC1ServiceUnSubscribe(topic: String)
    func TC1ServicePublish(messageId: Int)
}

extension TC1ServiceReceiveDelegate{
    func TC1ServiceOnConnect(){
        
    }
    func TC1ServiceDidDisconnect(error:Error?){
        
    }
    func TC1ServiceSubscribe(topic: String){
        
    }
    func TC1ServiceUnSubscribe(topic: String){
        
    }
    func TC1ServicePublish(messageId: Int){
        
    }
}

class TC1ServiceManager: NSObject {
    
    static let share = TC1ServiceManager()
    private var mqttClient: CocoaMQTT?
    private var udpSocket:GCDAsyncUdpSocket?
    private var mac = String()
    private(set) var isLocal = true
    private(set) var isConnect = false
    weak var delegate:TC1ServiceReceiveDelegate?
    
    //不传入设备则代表使用UDP广播
    //ip用于判断使用UDP还是MQTT
    func connectService(device:TCDeviceModel? = nil,ip:String? = nil){
        self.isLan(ip: ip) { [unowned self] (isLocal) in
            self.isLocal = isLocal
            if isLocal{
                print("当前为局域网环境")
                self.initTC1UDPService()
            }else{
                print("当前为外网环境")
                self.initTC1MQTTService(device: device)
            }
        }
    }
    
    func closeService(){
        print("close service")
        self.mqttClient?.disconnect()
        self.udpSocket?.close()
        self.mqttClient = nil
        self.udpSocket = nil
    }
    
    
    private func initTC1MQTTService(device:TCDeviceModel?){
        guard let device = device else {
            return
        }
        guard device.host != "" else {
            HUD.flash(HUDContentType.labeledError(title: "获取数据失败", subtitle: "当前设备没有配置MQTT服务器,无法在外网中获取到数据!"))
            return
        }
        guard device.port != 0 else{
            return
        }
        self.mac = device.mac
        self.mqttClient = CocoaMQTT(clientID: "CocoaMQTT" + device.clientId, host: device.host, port: UInt16(device.port))
        self.mqttClient?.username = device.username
        self.mqttClient?.password = device.password
        self.mqttClient?.keepAlive = 60
        self.mqttClient?.delegate = self
        self.mqttClient?.logLevel = .warning
        self.mqttClient?.cleanSession = true
        self.mqttClient?.autoReconnect = true
        self.mqttClient?.connect()
    }
    
    private func initTC1UDPService(){
        self.udpSocket = GCDAsyncUdpSocket(delegate: self, delegateQueue: DispatchQueue.global())
        do {
            try self.udpSocket?.enableBroadcast(true)
            try self.udpSocket?.bind(toPort: 10181)
            try self.udpSocket?.beginReceiving()
            //UDP只是接受数据用,所以不会触发连接成功的代理
            self.delegate?.TC1ServiceOnConnect()
        } catch  {
            print("UDP Error\(error.localizedDescription)")
        }
    }
    
    //    判断是否在同一个局域网,IP为空则默认为UDP通讯!
    private func isLan(ip:String?,_ realReachabilitySatas:@escaping (Bool)->Void){
        guard EASYLINK.getIPAddress() != "" else {
            //WIFI没有开启或者SSID为空
            realReachabilitySatas(false)
            return
        }
        
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

extension TC1ServiceManager{
    func subscribeDeviceMessage(mac:String,qos:Int = 0){
        self.mqttClient?.subscribe("device/ztc1/" + self.mac + "/state", qos: CocoaMQTTQOS.init(rawValue: UInt8(qos))!)
    }
    
    func unSubscribeDeviceMessage(mac:String){
        self.mqttClient?.unsubscribe("device/ztc1/" + mac  + "/state")
    }
    
    
    func publishMessage(_ message:[String:Any],qos:Int = 0){
        if let jsonString = JSON(message).rawString(.utf8, options: .init(rawValue: 0)){
            if self.isLocal{
                self.udpSocket?.send(jsonString.data(using: String.Encoding.utf8)!, toHost: "255.255.255.255", port: 10182, withTimeout: 60, tag: Int.random(in: 1...100))
                print("publishMessage With UDP -> \(jsonString)")
            }else{
                if self.isConnect{
                    self.mqttClient!.publish("device/ztc1/set", withString: jsonString, qos: CocoaMQTTQOS(rawValue: UInt8(qos))!, retained: true, dup: true)
                    print("publishMessage With MQTT -> \(jsonString)")
                }
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
        let cmd = ["name":name,"mac":mac,"version":nil,
                   "setting":["mqtt_uri":nil,"mqtt_port":nil,"mqtt_user":nil,"mqtt_password":nil],
                   "plug_0":["setting":["name":nil]],
                   "plug_1":["setting":["name":nil]],
                   "plug_2":["setting":["name":nil]],
                   "plug_3":["setting":["name":nil]],
                   "plug_4":["setting":["name":nil]],
                   "plug_5":["setting":["name":nil]]
            ] as [String : Any?]
        self.publishMessage(cmd as [String : Any],qos: 1)
    }
}

extension TC1ServiceManager:CocoaMQTTDelegate{
    
    func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
        if ack == .accept {
            self.isConnect = true
            self.delegate?.TC1ServiceOnConnect()
        }else{
            print("连接MQTT异常--->\(ack.description)")
        }
        
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
        self.delegate?.TC1ServicePublish(messageId: Int(id))
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {
        
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16) {
        if let string = message.string,let messageData = string.data(using: .utf8){
          self.delegate?.TC1ServiceReceivedMessage(message: messageData)
        }
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopic topic: String) {
        print("订阅---> \(topic)")
        self.delegate?.TC1ServiceSubscribe(topic: topic)
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopic topic: String) {
        self.delegate?.TC1ServiceUnSubscribe(topic: topic)
    }
    
    func mqttDidPing(_ mqtt: CocoaMQTT) {
        
    }
    
    func mqttDidReceivePong(_ mqtt: CocoaMQTT) {
        
    }
    
    func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {
        self.isConnect = false
        self.delegate?.TC1ServiceDidDisconnect(error: err)
    }
    
    
}


extension TC1ServiceManager:GCDAsyncUdpSocketDelegate{
    
    //UDP
    func udpSocket(_ sock: GCDAsyncUdpSocket, didSendDataWithTag tag: Int) {
        self.delegate?.TC1ServicePublish(messageId: tag)
    }
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didNotConnect error: Error?) {
        self.delegate?.TC1ServiceDidDisconnect(error: error)
    }
    
    func udpSocketDidClose(_ sock: GCDAsyncUdpSocket, withError error: Error?) {
        self.delegate?.TC1ServiceDidDisconnect(error: error)
    }
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didConnectToAddress address: Data) {
        self.delegate?.TC1ServiceOnConnect()
    }
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didNotSendDataWithTag tag: Int, dueToError error: Error?) {
        print("Tag为\(tag) 发送失败! ERROR-> \(String(describing: error?.localizedDescription))")
    }
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?) {
        DispatchQueue.main.async {
            self.delegate?.TC1ServiceReceivedMessage(message:data)
        }
    }
    
}
