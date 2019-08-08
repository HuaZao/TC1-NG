//
//  FXDeviceInfoTableViewController.swift
//  TC1-NG
//
//  Created by QAQ on 2019/4/25.
//  Copyright © 2019 TC1. All rights reserved.
//

import UIKit
import SwiftyJSON
import PKHUD

class FXDeviceInfoTableViewController: UITableViewController {
    
    @IBOutlet weak var ipAddress: UILabel!
    @IBOutlet weak var macAddress: UILabel!
    @IBOutlet weak var mqttAddress: UILabel!
    @IBOutlet weak var version: UILabel!
    @IBOutlet weak var deviceName: UILabel!
    @IBOutlet weak var connectLabel: UILabel!
    @IBOutlet weak var runTimerLabel: UILabel!
    @IBOutlet weak var isMQTT: UISwitch!
    @IBOutlet weak var deviceLock: UILabel!
    @IBOutlet weak var deviceTypeName: UILabel!
    
    var deviceModel = TCDeviceModel()
    private var totalTimer:Int32 = 0
    private var timer:Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.ipAddress.text = self.deviceModel.ip
        self.macAddress.text = self.deviceModel.mac
        self.mqttAddress.text = self.deviceModel.host
        self.version.text = self.deviceModel.version
        self.deviceName.text = self.deviceModel.name
        self.isMQTT.isOn = self.deviceModel.isOnline
        APIServiceManager.share.delegate = self
        APIServiceManager.share.subscribeDeviceMessage()
        if APIServiceManager.share.isLocal{
            self.connectLabel.text = "UDP"
        }else{
            self.connectLabel.text = "MQTT"
        }
        if self.deviceModel.isActivate{
            self.deviceLock.text = "设备已激活"
        }else{
            self.deviceLock.text = "设备未激活"
        }
        switch self.deviceModel.type {
        case .TC1:
            self.deviceTypeName.text = "TC1智能排插"
        case .DC1:
            self.deviceTypeName.text = "DC1智能排插"
        case .A1:
            self.deviceTypeName.text = "悟净A1空气净化器"
        }
        self.tableView.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.timer?.invalidate()
        self.timer = nil
    }
    
    @IBAction func rebootAction(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "警告", message: "是否立即重启设备?(需要版本v0.10.1及以上版本)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        let reboot = UIAlertAction(title: "确认", style: .destructive, handler: { (_) in
            APIServiceManager.share.publishMessage(["mac":self.deviceModel.mac,"cmd":"restart"],qos:1)
            HUD.flash(.labeledSuccess(title: nil, subtitle: "请求已发送"), delay: 2)
        })
        alert.addAction(reboot)
        self.present(alert, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? FXSetMQTTServiceViewController{
            vc.deviceModel = self.deviceModel
        }
    }
    
    
    @IBAction func alwaysUseMQTTAction(_ sender: UISwitch) {
        if self.deviceModel.host != ""{
            self.deviceModel.isOnline = sender.isOn
            TCSQLManager.updateTCDevice(self.deviceModel)
            HUD.flash(.labeledSuccess(title: "设置成功", subtitle: "重新打开APP之后生效!"), delay: 1)
        }else{
            if sender.isOn{
                HUD.flash(HUDContentType.labeledError(title: "无法设置", subtitle: "MQTT服务端尚未设置!"), delay: 1)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0{
            self.reNameAction()
        }else if indexPath.row == 5{
            self.activateDevice()
        }else if indexPath.row == 9{
            self.checkForUpdates()
        }else if indexPath.row == 1 || indexPath.row == 3{
            if let cell = tableView.cellForRow(at: indexPath),let content = cell.detailTextLabel?.text{
                let pasteboard = UIPasteboard.general
                pasteboard.string = content
                HUD.flash(.labeledSuccess(title: nil, subtitle: "复制成功"), delay: 1)
            }
        }
    }
    
    private func activateDevice(){
        if self.deviceModel.isActivate{
            HUD.flash(.labeledSuccess(title: "设备已激活", subtitle: nil), delay: 2.0)
            return
        }
        let alert = UIAlertController(title: "激活设备", message: "请输入激活码(激活码和固件不需要任何费用,请勿上当受骗)", preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = "请输入激活码"
        }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        let reNameAction = UIAlertAction(title: "确认", style: .destructive, handler: { (_) in
            if let unLockString = alert.textFields!.first?.text,unLockString.count > 0{
                APIServiceManager.share.activateDevice(lock: unLockString)
                HUD.flash(.labeledSuccess(title: nil, subtitle: "请求已发送"), delay: 2)
            }else{
                HUD.flash(.labeledError(title: nil, subtitle: "请输入激活码"), delay: 2)
            }
        })
        alert.addAction(reNameAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    private func reNameAction(){
        let alert = UIAlertController(title: "重命名", message: "请输入新名字", preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = "请输入新名字"
        }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        let reNameAction = UIAlertAction(title: "确认", style: .destructive, handler: { (_) in
            if let name = alert.textFields!.first?.text,name.count > 0{
                APIServiceManager.share.publishMessage(["mac":self.deviceModel.mac,"setting":["name":name]],qos:1)
                HUD.flash(.labeledSuccess(title: nil, subtitle: "请求已发送"), delay: 2)
                self.deviceModel.name = name
                self.deviceName.text = self.deviceModel.name
                self.tableView.reloadData()
                TCSQLManager.updateTCDevice(self.deviceModel)
            }else{
                HUD.flash(.labeledError(title: nil, subtitle: "请输入新名字"), delay: 2)
            }
        })
        alert.addAction(reNameAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    private func checkForUpdates(){
        let alert = UIAlertController(title: "OTA更新", message: "请选择更新方式", preferredStyle: .actionSheet)
        let userAction = UIAlertAction(title: "自定义OTA地址", style: .default) { (_) in
            self.userDefinedService()
        }
        let wulaAction = UIAlertAction(title: "软件内置OTA地址", style: .default) { (_) in
            self.wulaService()
        }
        alert.addAction(userAction)
        alert.addAction(wulaAction)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    private func userDefinedService(){
        let alert = UIAlertController(title: "请输入OTA地址", message: "当前软件版本为\(self.version.text!)", preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = "请输入OTA地址"
        }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        let update = UIAlertAction(title: "确认", style: .destructive, handler: { (_) in
            if let otaString = alert.textFields?.first!.text,otaString.hasPrefix("http"){
                APIServiceManager.share.publishMessage(["mac":self.deviceModel.mac,"setting":["ota":otaString]])
                HUD.show(.labeledProgress(title: "正在更新", subtitle: "请勿断开设备电源!"))
            }else{
                HUD.flash(.labeledError(title: "OTA失败", subtitle: "OTA地址输入有误"))
            }
        })
        alert.addAction(update)
        self.present(alert, animated: true, completion: nil)
        
    }
    
    private func wulaService(){
        DispatchQueue.global().async {
            do{
                var url:URL!
                var otaUrl:URL!
                switch self.deviceModel.type{
                case .TC1:
                    url = URL(string: "http://fx.tanwan.site:4380/zTC1.json")
                    otaUrl = URL(string: "http://fx.tanwan.site:4380/TC1_OTA.bin")
                case .DC1:
                    url = URL(string: "http://fx.tanwan.site:4380/zDC1.json")
                    otaUrl = URL(string: "http://fx.tanwan.site:4380/DC1_OTA.bin")
                case .A1:
                    url = URL(string: "http://fx.tanwan.site:4380/zA1.json")
                    otaUrl = URL(string: "http://fx.tanwan.site:4380/A1_OTA.bin")
                }
                let jsonData = try Data(contentsOf: url!)
                if let version = JSON(jsonData)["version"].string,let message = JSON(jsonData)["message"].string{
                    if self.deviceModel.version != version{
                        DispatchQueue.main.async {
                            let alert = UIAlertController(title: "\(self.deviceTypeName.text!)检测到新版本", message:message, preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "暂不更新", style: .cancel, handler: nil))
                            let update = UIAlertAction(title: "马上更新", style: .destructive, handler: { (_) in
                                APIServiceManager.share.publishMessage(["mac":self.deviceModel.mac,"setting":["ota":otaUrl]])
                                HUD.show(.labeledProgress(title: "正在更新", subtitle: "请勿断开设备电源!"))
                            })
                            alert.addAction(update)
                            self.present(alert, animated: true, completion: nil)
                        }
                    }else{
                        DispatchQueue.main.async {
                            HUD.flash(.labeledSuccess(title: "已经是最新版本", subtitle: nil), delay: 2)
                        }
                    }
                }
            }catch{
                DispatchQueue.main.async {
                    HUD.flash(.labeledError(title: "更新失败", subtitle: error.localizedDescription), delay: 2)
                }
            }
        }
    }
    
    @objc private func updateTotalTimer(timer:Timer){
        if self.totalTimer > 0 {
            self.totalTimer = self.totalTimer + 1
            let days = self.totalTimer / (3600 * 24)
            let hours = (self.totalTimer / 3600) % 24
            let minutes = (self.totalTimer / 60) % 60
            let seconds = self.totalTimer % 60
            self.runTimerLabel.text = String(format: "%02d天%02d时%02d分%02d秒", days,hours,minutes,seconds)
        }
    }
    
}


extension FXDeviceInfoTableViewController:APIServiceReceiveDelegate{
    
    func DeviceServiceReceivedMessage(message: Data) {
        let messageJSON = try! JSON(data: message)
        let  totalTimer = messageJSON["total_time"].int32Value
        if totalTimer > 0 && self.timer == nil{
            //只赋值一次,避免多次赋值,影响UI刷新
            self.totalTimer = totalTimer
            self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.updateTotalTimer(timer:)), userInfo: nil, repeats: true)
        }
        let otaProgress = messageJSON["ota_progress"].floatValue
        if otaProgress > 0{
            print("OTA 进度 ---> \(otaProgress)")
        }
        if otaProgress == 100 {
            DispatchQueue.main.async {
                HUD.flash(.labeledSuccess(title: "更新成功!", subtitle: nil))
            }
        }
        
    }
    
    func DeviceServicePublish(messageId: Int) {
        print("指令已经发送!")
    }
    
    
}
