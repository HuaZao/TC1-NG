//
//  TCSetMQTTServiceViewController.swift
//  TC1-NG
//
//  Created by QAQ on 2019/4/26.
//  Copyright © 2019 TC1. All rights reserved.
//

import UIKit
import PKHUD

class TCSetMQTTServiceViewController: UIViewController {
    
    @IBOutlet weak var host: UITextField!
    @IBOutlet weak var port: UITextField!
    @IBOutlet weak var userName: UITextField!
    @IBOutlet weak var passWord: UITextField!
    
    var deviceModel = TCDeviceModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.host.text = self.deviceModel.host
        self.port.text = "\(self.deviceModel.port)"
        self.userName.text = self.deviceModel.username
        self.passWord.text = self.deviceModel.password
    }
    
    @IBAction func saveMQTTAction(_ sender: UIButton) {
        guard let mqtt_uri = host.text,mqtt_uri.count > 0 else {
            return
        }
        
        guard let mqtt_port = Int32(port.text ?? "0"),mqtt_port > 0 else {
            return
        }
        
        let cmd:[String:Any] = [
            "name":self.deviceModel.name,
            "mac":self.deviceModel.mac,
            "setting":[
                "mqtt_uri":mqtt_uri,
                "mqtt_port":mqtt_port,
                "mqtt_user":self.getUserName() as Any,
                "mqtt_password":self.getPassword() as Any
            ]
        ]
        //QOS使用1,保证消息能d到达
        TC1ServiceManager.share.publishMessage(cmd,qos: 1)
        HUD.flash(.labeledSuccess(title: "请求已经发送", subtitle: "请耐心等待生效"), delay: 2.0)
        self.navigationController?.popViewController(animated: true)
    }
    
    private func getPassword()->String?{
        if let string = self.passWord.text,string.count > 0{
            return string
        }else{
            return nil
        }
    }
    
    private func getUserName()->String?{
        if let string = self.userName.text,string.count > 0{
            return string
        }else{
            return nil
        }
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
}
