//
//  FXDeviceMainViewController.swift
//  TC1-NG
//
//  Created by cpu on 2019/8/5.
//  Copyright © 2019 TC1. All rights reserved.
//

import UIKit
import RealReachability
import PKHUD
import SwiftyJSON

class FXDeviceMainViewController: UIViewController,APIServiceReceiveDelegate{
    var deviceModel = TCDeviceModel()
    var isReload = true
    var needUpdate = false

    private var isAlert = false

    override func viewDidLoad() {
        super.viewDidLoad()
        self.obNetworkStateChange()
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.isReload = true
        self.title = self.deviceModel.name
        self.connectionDevice()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.isReload = false
    }
    
    
    func connectionDevice(){
        APIServiceManager.share.connectService(device: self.deviceModel, ip: self.deviceModel.ip)
        APIServiceManager.share.delegate = self
    }
    
    private func activateDevice(){
        if self.deviceModel.type == .M1{return}
        if self.isAlert{return}
        self.isAlert = true
        let alert = UIAlertController(title: "设备激活", message: "设备尚未激活(激活码和固件不需要任何费用,请勿上当受骗)", preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = "请输入激活码"
        }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: {(_) in
            self.isAlert = false
        }))
        let unLockAction = UIAlertAction(title: "激活", style: .destructive, handler: { (_) in
            if let unLockString = alert.textFields!.first?.text,unLockString.count > 0{
                APIServiceManager.share.activateDevice(lock: unLockString)
                HUD.flash(.labeledSuccess(title: "成功", subtitle: "激活请求已发送,请耐心等待生效"), delay: 1)
            }else{
                HUD.flash(.labeledError(title: nil, subtitle: "请输入激活码"), delay: 1)
            }
            self.isAlert = false
        })
        alert.addAction(unLockAction)
        self.present(alert, animated: true, completion: nil)
    }

    private func obNetworkStateChange(){
        let realReachability = RealReachability.sharedInstance()
        realReachability?.hostForPing = "www.baidu.com"
        realReachability?.startNotifier()
        NotificationCenter.default.addObserver(self, selector: #selector(self.networkStateChange(sender:)), name: NSNotification.Name.realReachabilityChanged, object: nil)
    }
    
    func updateDevice(message:JSON){
        if let version = message["version"].string{
            self.needUpdate = true
            self.deviceModel.version = version
        }
        if let mqtt_uri = message["setting"]["mqtt_uri"].string{
            self.needUpdate = true
            self.deviceModel.host = mqtt_uri
        }
        if let mqtt_port = message["setting"]["mqtt_port"].int{
            self.needUpdate = true
            self.deviceModel.port = mqtt_port
        }
        if let mqtt_user = message["setting"]["mqtt_user"].string{
            self.needUpdate = true
            self.deviceModel.username = mqtt_user
        }
        if let mqtt_password = message["setting"]["mqtt_password"].string{
            self.needUpdate = true
            self.deviceModel.password = mqtt_password
        }
        if let name = message["name"].string{
            self.needUpdate = true
            self.deviceModel.name = name
        }
        if self.needUpdate{
            self.needUpdate = false
            TCSQLManager.updateTCDevice(self.deviceModel)
        }
    }
    
    @objc private func networkStateChange(sender:NotificationCenter){
        APIServiceManager.share.closeService()
        APIServiceManager.share.connectService(device: self.deviceModel, ip: self.deviceModel.ip)
    }
    
    
    @IBAction func dimissViewController(_ sender: UIBarButtonItem) {
        self.isReload = false
        APIServiceManager.share.unSubscribeDeviceMessage()
        APIServiceManager.share.closeService()
        self.navigationController?.popViewController(animated: true)
    }
    
    
    func DeviceServiceOnConnect() {
        if !APIServiceManager.share.isLocal{
            print("MQTT服务器连接成功!")
            APIServiceManager.share.subscribeDeviceMessage()
            APIServiceManager.share.isDeviceActivate()
            APIServiceManager.share.getDeviceFullState()
        }else{
            print("UDP已经准备就绪!")
            DispatchQueue.global().async {
                //UDP不太稳定,采用轮询机制访问
                while self.isReload{
                    if !self.deviceModel.isActivate{
                        APIServiceManager.share.isDeviceActivate()
                    }
                    APIServiceManager.share.getDeviceFullState()
                    sleep(1)
                }
            }
        }
    }
    
    func DeviceServiceReceivedMessage(message: Data) {
        let messageJSON = try! JSON(data: message)
        print(messageJSON)

        if messageJSON["mac"].stringValue != self.deviceModel.mac{
            return
        }
        if let lock = messageJSON["lock"].string{
            if lock == "false"{
                DispatchQueue.main.async {
                    self.activateDevice()
                }
                self.deviceModel.isActivate = false
            }else{
                self.deviceModel.isActivate = true
            }
        }
        self.updateDevice(message: messageJSON)
    }
    
    func DeviceServiceUnSubscribe(topic: String) {
        print("退订成功! \(topic)")
    }
    
    func DeviceServiceSubscribe(topics: [String]) {
        print("订阅\(topics)")
    }

}

