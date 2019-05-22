//
//  TCDeviceInfoTableViewController.swift
//  TC1-NG
//
//  Created by QAQ on 2019/4/25.
//  Copyright © 2019 TC1. All rights reserved.
//

import UIKit
import SwiftyJSON
import PKHUD

class TCDeviceInfoTableViewController: UITableViewController {

    @IBOutlet weak var ipAddress: UILabel!
    @IBOutlet weak var macAddress: UILabel!
    @IBOutlet weak var mqttAddress: UILabel!
    @IBOutlet weak var version: UILabel!
    @IBOutlet weak var deviceName: UILabel!
    @IBOutlet weak var connectLabel: UILabel!
    @IBOutlet weak var isMQTT: UISwitch!
    
    var deviceModel = TCDeviceModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.ipAddress.text = self.deviceModel.ip
        self.macAddress.text = self.deviceModel.mac
        self.mqttAddress.text = self.deviceModel.host
        self.version.text = self.deviceModel.version
        self.deviceName.text = self.deviceModel.name
        self.isMQTT.isOn = self.deviceModel.isOnline
        TC1ServiceManager.share.delegate = self
        TC1ServiceManager.share.subscribeDeviceMessage()
        if TC1ServiceManager.share.isLocal{
            self.connectLabel.text = "UDP"
        }else{
            self.connectLabel.text = "MQTT"
        }
        self.tableView.reloadData()
    }
    
    @IBAction func rebootAction(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "警告", message: "是否立即重启设备?(需要版本v0.10.1及以上版本)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        let reboot = UIAlertAction(title: "确认", style: .destructive, handler: { (_) in
            TC1ServiceManager.share.publishMessage(["mac":self.deviceModel.mac,"cmd":"restart"],qos:1)
            HUD.flash(.labeledSuccess(title: nil, subtitle: "请求已发送"), delay: 2)
        })
        alert.addAction(reboot)
        self.present(alert, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? TCSetMQTTServiceViewController{
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
            let alert = UIAlertController(title: "重命名", message: "请输入新名字", preferredStyle: .alert)
            alert.addTextField { (textField) in
                textField.placeholder = "请输入新名字"
            }
            alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
            let reNameAction = UIAlertAction(title: "确认", style: .destructive, handler: { (_) in
                if let name = alert.textFields!.first?.text,name.count > 0{
                    TC1ServiceManager.share.publishMessage(["mac":self.deviceModel.mac,"setting":["name":name]],qos:1)
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
        }else if indexPath.row == 5{
            self.checkForUpdates()
        }else if indexPath.row == 1 || indexPath.row == 2{
            if let cell = tableView.cellForRow(at: indexPath),let content = cell.textLabel?.text{
                let pasteboard = UIPasteboard.general
                pasteboard.string = content
                HUD.flash(.labeledSuccess(title: nil, subtitle: "复制成功"), delay: 1)
            }
        }
    }
    
    private func checkForUpdates(){
        DispatchQueue.global().async {
            do{
                let url = URL(string: "http://home.wula.vip:4380/TC.json")
                let jsonData = try Data(contentsOf: url!)
                if let version = JSON(jsonData)["version"].string{
                    if self.deviceModel.version != version{
                        let alert = UIAlertController(title: "检测到新版本", message: "服务器最新版本为\(version),是否马上更新?", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "暂不更新", style: .cancel, handler: nil))
                        let update = UIAlertAction(title: "马上更新", style: .destructive, handler: { (_) in
                            TC1ServiceManager.share.publishMessage(["mac":self.deviceModel.mac,"setting":["ota":"http://home.wula.vip:4380/TC1_OTA.bin"]])
                            DispatchQueue.main.async {
                                HUD.show(.labeledProgress(title: "正在更新", subtitle: "请勿断开设备电源!"))
                            }
                        })
                        alert.addAction(update)
                        DispatchQueue.main.async {
                            self.present(alert, animated: true, completion: nil)
                        }
                    }else{
                        DispatchQueue.main.async {
                            HUD.flash(.labeledSuccess(title: "已经是最新版本", subtitle: nil), delay: 2)
                        }
                    }
                }
            }catch{
                print("更新失败 ->\(error.localizedDescription)")
            }
        }
    }

}


extension TCDeviceInfoTableViewController:TC1ServiceReceiveDelegate{
    
    func TC1ServiceReceivedMessage(message: Data) {
        let messageJSON = try! JSON(data: message)
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
    
    func TC1ServicePublish(messageId: Int) {
        print("指令已经发送!")
    }
    
    
}
