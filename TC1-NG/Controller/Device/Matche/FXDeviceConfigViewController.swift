//
//  FXDeviceConfigViewController.swift
//  TC1-NG
//
//  Created by QAQ on 2019/4/25.
//  Copyright © 2019 TC1. All rights reserved.
//

import UIKit
import SwiftyJSON
import PKHUD

class FXDeviceConfigViewController: UIViewController {
    
    @IBOutlet weak var wifiName: UILabel!
    @IBOutlet weak var wifiPass: UITextField!
    
    fileprivate var easyLink:EASYLINK?
    fileprivate var serviceDataSource = [NetService]()
    fileprivate var serviceInfoDataSource = [[String:String]]()
    fileprivate var moreComing = true
    fileprivate var ssidData:Data?
    fileprivate var isSend = false

    override func viewDidLoad() {
        super.viewDidLoad()
        APIServiceManager.share.delegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.isSend = false
        self.easyLink?.unInit()
        APIServiceManager.share.closeService()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.isSend = true
        if let wifiName = String(data: EASYLINK.ssidDataForConnectedNetwork(), encoding: String.Encoding.utf8){
            self.wifiName.text = wifiName
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.wifiPass.resignFirstResponder()
    }
    
    @IBAction func wifiCustomAction(_ sender: UIButton) {
        let alert = UIAlertController(title: "测试模式", message: "请输入WiFi名称", preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = "请输入WiFi名称"
            textField.tag = 1001
        }
        let affirm = UIAlertAction(title: "确定", style: .default) { (_) in
            if let ssidString = alert.textFields!.first?.text,let ssidData = ssidString.data(using: String.Encoding.utf8){
                self.wifiName.text = ssidString
                self.ssidData = ssidData
            }
        }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        alert.addAction(affirm)
        self.present(alert, animated: true, completion: nil)
    }
    
    
    @IBAction func discoverLocalDevice(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "添加已配对设备", message: "请确保设备已经配对,并且接入MQTT服务器或处在同一个局域网", preferredStyle: .alert)
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
            textField.placeholder = "输入设备局域网IP地址"
            textField.tag = 1006
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
            guard let username = alert.textFields?.first(where: {$0.tag == 1003})?.text else{
                return
            }
            guard let password = alert.textFields?.first(where: {$0.tag == 1004})?.text else{
                return
            }
            guard let ip = alert.textFields?.first(where: {$0.tag == 1006})?.text else{
                return
            }
            guard let mac = alert.textFields?.first(where: {$0.tag == 1005})?.text else{
                return
            }
            self?.addTC(message: JSON(["name":mac,"ip":ip,"mac":mac,"mqtt_uri":host,"mqtt_port":iPort,"mqtt_user":username,"mqtt_password":password,"type":FXDeviceType.TC1.rawValue,"type_name":"zTC1"]))
        }))
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    fileprivate func addTC(message:JSON){
        _ = message.addDevice()
        DispatchQueue.main.async {
            self.navigationController?.popToRootViewController(animated: true)
        }
    }
    
    
    @IBAction func beginConfAction(_ sender: UIButton) {
        if let password = self.wifiPass.text{
            //        Step1: 初始化EasyLink实例
            self.easyLink = EASYLINK(forDebug: true, withDelegate: self)
             self.easyLink?.setDelegate(self)
            //        Step2: 设置配置参数
            if  self.ssidData == nil{
                ssidData = EASYLINK.ssidDataForConnectedNetwork()
            }
            //        EASYLINK AWS模式中使用UDP广播实现,其余的配网方式使用mDNS实现
            self.easyLink?.prepareEasyLink(["SSID":self.ssidData!,"PASSWORD":password,"DHCP":NSNumber(booleanLiteral: true)], info: nil, mode: EASYLINK_V2_PLUS)
            //        Step3: 开始发送配网信息
            self.easyLink?.transmitSettings()
            HUD.flash(.labeledProgress(title: "配网中", subtitle: nil))
            //EASYLINK 配网成功之后并不会走任何回调,这里使用UDP轮询发送
            self.pollService()
        }
    }
    
    private func pollService(){
        APIServiceManager.share.connectUDPService()
        DispatchQueue.global().async {
            while self.isSend{
                APIServiceManager.share.sendDeviceReportCmd()
                sleep(1)
            }
        }
    }
    
    
    
}

extension FXDeviceConfigViewController:APIServiceReceiveDelegate,EasyLinkFTCDelegate{
    
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
    
    func onEasyLinkSoftApStageChanged(_ stage: EasyLinkSoftApStage) {
        
    }
    
    /**
     @brief 新设备发现回调 通过Bonjour服务查找MiCO设备的地址
     @param client: 客户端编号（可以忽略）
     @param name: 设备名称，就是设备在mDNS服务中提供的实例名称
     @param mataDataDict: 元数据，即使设备在mDNS服务中提供的TXT Record，或者UDP广播中提供的JSON数据
     @return none.
     */
    func onFound(_ client: NSNumber!, withName name: String!, mataData mataDataDict: [AnyHashable : Any]!) {
        
    }
    
    func onDisconnect(fromFTC client: NSNumber!, withError err: Bool) {
        
    }
    
    
    func DeviceServiceReceivedMessage(message: Data) {
        let messageJSON = try! JSON(data: message)
        //如果有IP信息,则添加设备!
        let ip = messageJSON["ip"].stringValue
        DispatchQueue.main.async {
            if ip.count > 0 && !TCSQLManager.deciveisExist(messageJSON["mac"].stringValue) {
                HUD.hide()
                self.addTC(message: messageJSON)
            }
        }
    }
    
    
}
