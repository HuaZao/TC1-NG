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
    
    var deviceModel = TCDeviceModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.ipAddress.text = self.deviceModel.ip
        self.macAddress.text = self.deviceModel.mac
        self.mqttAddress.text = self.deviceModel.mqtt.host
        self.version.text = self.deviceModel.version
        TC1MQTTManager.share.delegate = self
        TC1MQTTManager.share.subscribeDeviceMessage(mac: self.deviceModel.mac)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? TCSetMQTTServiceViewController{
            vc.deviceModel = self.deviceModel
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0{
            
        }
        if indexPath.row == 4{
            self.checkForUpdates()
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
                            TC1MQTTManager.share.publishMessage(["mac":self.deviceModel.mac,"setting":["ota":"http://home.wula.vip:4380/TC1_OTA.bin"]])
                            DispatchQueue.main.async {
                                HUD.flash(.labeledProgress(title: "正在更新", subtitle: "请勿退出程序"), delay: 2)
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


extension TCDeviceInfoTableViewController:TC1MQTTManagerDelegate{
    
    func TC1MQTTManagerReceivedMessage(message: Data) {
        let messageJSON = try! JSON(data: message)
        print(messageJSON)
    }
    
    func TC1MQTTManagerPublish(messageId: Int) {
        print("更新指令已经发送!")
    }
    
    
}
