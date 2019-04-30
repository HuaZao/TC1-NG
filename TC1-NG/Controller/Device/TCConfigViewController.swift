//
//  TCConfigViewController.swift
//  TC1-NG
//
//  Created by QAQ on 2019/4/25.
//  Copyright © 2019 TC1. All rights reserved.
//

import UIKit
import SwiftyJSON

class TCConfigViewController: UIViewController {
    
    @IBOutlet weak var wifiName: UILabel!
    @IBOutlet weak var wifiPass: UITextField!
    
    fileprivate var easyLink:EASYLINK?
    fileprivate var netServiceBrowser:NetServiceBrowser?
    fileprivate var serviceDataSource = [NetService]()
    fileprivate var serviceInfoDataSource = [[String:String]]()
    fileprivate var moreComing = true
    override func viewDidLoad() {
        super.viewDidLoad()
        TC1MQTTManager.share.delegate = self
        //不知道什么问题使用easyLink配网是不会触发官方的任何代理协议,这里使用BonjourService发现设备!
        self.netServiceBrowser = NetServiceBrowser()
        self.netServiceBrowser?.searchForServices(ofType: "_easylink._tcp", inDomain: "local")
        self.netServiceBrowser?.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let wifiName = String(data: EASYLINK.ssidDataForConnectedNetwork(), encoding: String.Encoding.utf8){
            self.wifiName.text = wifiName
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.wifiPass.resignFirstResponder()
    }
    
    @IBAction func discoverLocalDevice(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "添加已配对设备", message: "请确保设备已经配对,并且接入MQTT服务器🍭", preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.keyboardType = .asciiCapable
            textField.placeholder = "输入Host"
            textField.tag = 1001
        }
        alert.addTextField { (textField) in
            textField.keyboardType = .numberPad
            textField.placeholder = "输入设备Port"
            textField.tag = 1002
        }
        alert.addTextField { (textField) in
            textField.keyboardType = .asciiCapable
            textField.placeholder = "输入用户名"
            textField.tag = 1003
        }
        alert.addTextField { (textField) in
            textField.keyboardType = .asciiCapable
            textField.placeholder = "输入密码"
            textField.tag = 1004
        }
        alert.addTextField { (textField) in
            textField.keyboardType = .asciiCapable
            textField.placeholder = "输入设备mac地址"
            textField.tag = 1005
        }
        alert.addAction(UIAlertAction(title: "确认", style: .default, handler: { [weak self] _ in
            guard let host = alert.textFields?.first(where: {$0.tag == 1001})?.text else {
                return
            }
            guard let port = alert.textFields?.first(where: {$0.tag == 1002})?.text,let iPort = Int(port) else{
                return
            }
            guard let userName = alert.textFields?.first(where: {$0.tag == 1003})?.text else{
                return
            }
            guard let userPassword = alert.textFields?.first(where: {$0.tag == 1004})?.text else{
                return
            }
            guard let mac = alert.textFields?.first(where: {$0.tag == 1005})?.text else{
                return
            }
            let model = MQTTModel()
            model.clientId = "clientId"
            model.host = host
            model.port = iPort
            model.username = userName
            model.password = userPassword
            self?.discoverDevices(mac:mac, service: model)
        }))
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    private func discoverDevices(mac:String,service:MQTTModel? = nil){
        //请求设备info
        TC1MQTTManager.share.initTC1Service(service,mac: mac)
        TC1MQTTManager.share.sendDeviceReportCmd()
    }
    
    fileprivate func addTC(message:JSON){
        let model = TCDeviceModel()
        model.name = message["name"].stringValue
        model.mac = message["mac"].stringValue
        model.ip = message["ip"].stringValue
        model.sockets = [SocketModel]()
        //初始化6个插座
        for i in 1...6{
            let socket = SocketModel()
            socket.isOn = false
            socket.socketId = model.mac + "_\(i)"
            socket.sockeTtitle = "插座S\(i)"
            model.sockets.append(socket)
        }
        TCSQLManager.addTCDevice(model)
        TC1MQTTManager.share.unSubscribeDeviceMessage(mac: model.mac)
        DispatchQueue.main.async {
            self.navigationController?.popToRootViewController(animated: true)
        }
    }
    
    
    @IBAction func beginConfAction(_ sender: UIButton) {
        if let password = self.wifiPass.text{
            self.easyLink?.unInit()
            //        Step1: 初始化EasyLink实例
            self.easyLink = EASYLINK(forDebug: true, withDelegate: self)
            //        Step2: 设置配置参数
            let ssidData = EASYLINK.ssidDataForConnectedNetwork()
            //        EASYLINK AWS模式中使用UDP广播实现,其余的配网方式使用mDNS实现
            self.easyLink?.prepareEasyLink(["SSID":ssidData!,"PASSWORD":password,"DHCP":NSNumber(booleanLiteral: true)], info: nil, mode: EASYLINK_AWS)
            //        Step3: 开始发送配网信息
            self.easyLink?.transmitSettings()
            
            //不知道什么问题使用easyLink配网是不会触发官方的任何代理协议,这里使用BonjourService发现设备!
            self.netServiceBrowser?.searchForServices(ofType: "_easylink._tcp", inDomain: "local")
        }
    }
    
}

extension TCConfigViewController:TC1MQTTManagerDelegate,EasyLinkFTCDelegate,NetServiceBrowserDelegate,NetServiceDelegate{
    
    func getIPV4StringfromAddress(address: [Data]) -> String{
        let data = address.first! as NSData;
        var ip1 = UInt8(0)
        data.getBytes(&ip1, range: NSMakeRange(4, 1))
        var ip2 = UInt8(0)
        data.getBytes(&ip2, range: NSMakeRange(5, 1))
        var ip3 = UInt8(0)
        data.getBytes(&ip3, range: NSMakeRange(6, 1))
        var ip4 = UInt8(0)
        data.getBytes(&ip4, range: NSMakeRange(7, 1))
        let ipStr = String(format: "%d.%d.%d.%d",ip1,ip2,ip3,ip4);
        return ipStr;
    }
    
    func netServiceDidResolveAddress(_ sender: NetService) {
        if let TXTRecord = sender.txtRecordData(){
            let serviceInfo = NetService.dictionary(fromTXTRecord:TXTRecord)
            var serviceDic = [String:String]()
            serviceInfo.forEach { dic in
                if let value = String(data: dic.value, encoding: String.Encoding.utf8){
                    serviceDic[dic.key] = value
                }
            }
            if let ipData = sender.addresses{
                serviceDic["IP"] = self.getIPV4StringfromAddress(address: ipData)
            }
            serviceDic["Port"] = "\(sender.port)"
            if let mac = serviceDic["MAC"]{
                if TCSQLManager.deciveisExist(mac.replacingOccurrences(of: ":", with: "").lowercased()) {
                    print("设备已存在!")
                }else{
                    self.serviceInfoDataSource.append(serviceDic)
                }
            }
        }
        //只发现了一个设备
        if let dic = self.serviceInfoDataSource.first,self.serviceInfoDataSource.count == 1,!self.moreComing{
            //判断是否TC1
            let jsonMessage = JSON(dic)
            if jsonMessage["Protocol"].stringValue == "com.zyc.basic"{
                print("发现TC1设备!")
                self.discoverDevices(mac: jsonMessage["MAC"].stringValue)
            }
        }
    }
    
    func netServiceDidStop(_ sender: NetService) {
        print("\(sender.name) 连接超时!")
    }
    
    func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
        print("\(sender.name) 无法解析-> \(errorDict)")
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        self.moreComing = moreComing
        self.serviceDataSource.append(service)
        service.delegate = self
        service.resolve(withTimeout: 5.0)
        if !moreComing {
            print("数据全部接受完毕")
        }
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        
    }
    
    /**
     如果设备上开启了Config Server功能，那么还会触发onFoundByFTC回调
     @brief 新设备发现回调
     @param client: 客户端编号
     @param name: configDict，设备在Config Server功能中提供的配置信息
     @return none.
     */
    func onFound(byFTC client: NSNumber!, withConfiguration configDict: [AnyHashable : Any]!) {
        //        如果触发了onFoundByFTC回调，就可以使用- (void)configFTCClient:(NSNumber *)client withConfiguration: (NSDictionary *)configDict;方法来设置设备参数了。但是这个功能也要和设备上的Config Server功能配合
        
        
    }
    
    /**
     @brief 新设备发现回调
     @param client: 客户端编号（可以忽略）
     @param name: 设备名称，就是设备在mDNS服务中提供的实例名称
     @param mataDataDict: 元数据，即使设备在mDNS服务中提供的TXT Record，或者UDP广播中提供的JSON数据
     @return none.
     */
    func onFound(_ client: NSNumber!, withName name: String!, mataData mataDataDict: [AnyHashable : Any]!) {
        
    }
    
    func onDisconnect(fromFTC client: NSNumber!, withError err: Bool) {
        
    }
    
    
    func TC1MQTTManagerReceivedMessage(message: Data) {
        let messageJSON = try! JSON(data: message)
        //如果有IP信息,则添加设备!
        let ip = messageJSON["ip"].stringValue
        if ip.count > 0 && !TCSQLManager.deciveisExist(messageJSON["mac"].stringValue) {
            self.addTC(message: messageJSON)
        }
        print(messageJSON)
    }
    
    
}
