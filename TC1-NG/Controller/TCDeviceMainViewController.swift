//
//  ViewController.swift
//  TC1-NG
//
//  Created by QAQ on 2019/4/19.
//  Copyright © 2019 TC1. All rights reserved.
//

import UIKit
import SwiftyJSON

class TCDeviceMainViewController: UIViewController {
    
    @IBOutlet weak var powerLabel: UILabel!
    @IBOutlet weak var powerView: PowerProgressView!
    @IBOutlet weak var socketCollectionView: UICollectionView!
    
    var deviceModel = TCDeviceModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        powerView.setCircleColor(color: UIColor.purple)
        powerView.animateToProgress(progress: 0)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        TC1MQTTManager.share.delegate = self
        TC1MQTTManager.share.subscribeDeviceMessage(mac: self.deviceModel.mac)
        TC1MQTTManager.share.getDeviceFullState(name: self.deviceModel.name, mac: self.deviceModel.mac)
    }
    
    @IBAction func dimissViewController(_ sender: UIBarButtonItem) {
        TC1MQTTManager.share.unSubscribeDeviceMessage(mac: self.deviceModel.mac)
        self.navigationController?.popViewController(animated: true)
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "info"{
            let vc = segue.destination as? TCDeviceInfoTableViewController
            vc?.deviceModel = self.deviceModel
        }
    }
        
    
    fileprivate func plugMessageReload(message:JSON){
        if let string = message.rawString(),string.contains("plug") == false{
            return
        }
        if let plug_0 = message["plug_0"].dictionaryValue["on"]?.boolValue{
            self.deviceModel.sockets[0].isOn = plug_0
        }
        if let plug_1 = message["plug_1"].dictionaryValue["on"]?.boolValue{
            self.deviceModel.sockets[1].isOn = plug_1
        }
        if let plug_2 = message["plug_2"].dictionaryValue["on"]?.boolValue{
            self.deviceModel.sockets[2].isOn = plug_2
        }
        if let plug_3 = message["plug_3"].dictionaryValue["on"]?.boolValue{
            self.deviceModel.sockets[3].isOn = plug_3
        }
        if let plug_4 = message["plug_4"].dictionaryValue["on"]?.boolValue{
            self.deviceModel.sockets[4].isOn = plug_4
        }
        if let plug_5 = message["plug_5"].dictionaryValue["on"]?.boolValue{
            self.deviceModel.sockets[5].isOn = plug_5
        }
        print(message)
        //更新这个设备的信息
        let mqtt = MQTTModel()
        self.deviceModel.version = message["version"].stringValue
        self.deviceModel.name = message["name"].stringValue
        mqtt.clientId = self.deviceModel.name
        mqtt.host = message["setting"]["mqtt_uri"].stringValue
        mqtt.port = message["setting"]["mqtt_port"].intValue
        mqtt.username = message["setting"]["mqtt_user"].stringValue
        mqtt.password = message["setting"]["mqtt_password"].stringValue
        self.deviceModel.mqtt = mqtt
        TCSQLManager.updateTCDevice(self.deviceModel)
        self.socketCollectionView.reloadData()
    }
    

}

extension TCDeviceMainViewController:TC1MQTTManagerDelegate{

    func TC1MQTTManagerReceivedMessage(message: Data) {
        DispatchQueue.main.async {
            let messageJSON = try! JSON(data: message)
            let power = messageJSON["power"].floatValue
            if power > 0 {
                self.powerView.animateToProgress(progress: 1/2500 * power)
                self.powerLabel.text = "\(power)W";
            }
            self.plugMessageReload(message: messageJSON)
        }
    }
    
    func TC1MQTTManagerSubscribe(messageId: Int, grantedQos: Array<Int32>) {
        
    }
    
    func TC1MQTTManagerUnSubscribe(messageId: Int) {
        print("退订成功!")
    }
    
    func TC1MQTTManagerPublish(messageId: Int) {
        
    }
    
    
}


extension TCDeviceMainViewController:UICollectionViewDelegateFlowLayout,UICollectionViewDelegate,UICollectionViewDataSource{
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.deviceModel.sockets.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let item = collectionView.dequeueReusableCell(withReuseIdentifier: "socketItem", for: indexPath) as! TCSocketItem
        item.titleLabel.text = self.deviceModel.sockets[indexPath.row].sockeTtitle
        item.socketButton.isSelected = self.deviceModel.sockets[indexPath.row].isOn
        return item
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = self.view.frame.width / 3
        return CGSize(width: width, height: width)
    }
    
    
}
