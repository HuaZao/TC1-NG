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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        TC1MQTTManager.share.delegate = self
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
        let alert = UIAlertController(title: "添加已配对设备", message: "请确保设备已经配对,并且接入WIFI🍭", preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.keyboardType = .asciiCapable
            textField.placeholder = "输入设备MAC(如d0bae463c730)"
        }
        alert.addAction(UIAlertAction(title: "确认", style: .default, handler: { [weak self] _ in
            if let mac = alert.textFields?.first?.text{
                self?.discoverDevices(mac: mac)
            }
        }))
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    private func discoverDevices(mac:String){
        //先订阅
        TC1MQTTManager.share.subscribeDeviceMessage(mac: mac)
        //请求设备info
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
        }
    }
    
}


extension TCConfigViewController:TC1MQTTManagerDelegate,EasyLinkFTCDelegate{
    
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
        if ip.count > 0 {
            self.addTC(message: messageJSON)
        }
        print(messageJSON)
    }
    
    
}
