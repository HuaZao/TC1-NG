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
    fileprivate var serviceDataSource = [NetService]()
    fileprivate var serviceInfoDataSource = [[String:String]]()
    fileprivate var moreComing = true
    fileprivate var ssidData:Data?
    fileprivate var isSend = false
    fileprivate var maxSend = 10
    
    
    var deviceiType:FXDeviceType = .DC1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        APIServiceManager.share.delegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.isSend = false
        APIServiceManager.share.closeService()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.isSend = true
//        if let wifiName = String(data: EASYLINK.ssidDataForConnectedNetwork(), encoding: String.Encoding.utf8){
//            self.wifiName.text = wifiName
//        }
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
            self?.addTC(message: JSON(["name":mac,"ip":ip,"mac":mac,"mqtt_uri":host,"mqtt_port":iPort,"mqtt_user":username,"mqtt_password":password,"type":self?.deviceiType.rawValue,"type_name":"zDC1"]))
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
            // 获得配置所需要的参数
//            if EASYLINK.ssidForConnectedNetwork() == nil || EASYLINK.ssidForConnectedNetwork() == ""{
//                HUD.flash(.labeledError(title: "WiFi名不能为空呀!", subtitle: "如果没识别出WiFi可以点击蓝色的图标手动输入"),delay:3.0)
//                return
//            }
//            self.esptouchTask?.interrupt()
//            self.esptouchTask = ESPTouchTask(apSsid:EASYLINK.ssidForConnectedNetwork(), andApBssid: EASYLINK.infoForConnectedNetwork()["BSSID"] as? String, andApPwd: password)
//            DispatchQueue.global().async {
//                self.esptouchTask?.executeForResult()
//            }
//            HUD.show(.labeledProgress(title: "配网中", subtitle: nil))
            //配网成功之后并不会走任何回调,这里使用UDP轮询发送
//            self.pollService()
            
    }
    
    private func pollService(){
        APIServiceManager.share.connectUDPService()
        var count = 0
        DispatchQueue.global().async {
            while self.isSend{
                count = count + 1
                if count >= self.maxSend{
                    self.isSend = false
//                    self.easyLink?.unInit()
//                    self.esptouchTask?.interrupt()
                    DispatchQueue.main.async {
                        HUD.flash(.labeledError(title: "配网超时!", subtitle: "请检查设备是否进入配网状态?"),delay:3.0)
                    }
                }
                APIServiceManager.share.sendDeviceReportCmd()
                sleep(1)
            }
        }
    }
    
    
    
}

extension FXDeviceConfigViewController:APIServiceReceiveDelegate{
    
    
    func DeviceServiceReceivedMessage(message: Data) {
        let messageJSON = try! JSON(data: message)
        //如果有IP信息,则添加设备!
        let ip = messageJSON["ip"].stringValue
        DispatchQueue.main.async {
            if ip.count > 0{
                HUD.hide()
                self.addTC(message: messageJSON)
            }
        }
    }
    
    
}
