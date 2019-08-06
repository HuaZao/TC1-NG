//
//  ViewController.swift
//  TC1-NG
//
//  Created by QAQ on 2019/4/19.
//  Copyright © 2019 TC1. All rights reserved.
//

import UIKit
import SwiftyJSON
import AudioToolbox
import RealReachability
import PKHUD

class TCDeviceMainViewController: FXDeviceMainViewController {
    
    @IBOutlet weak var powerLabel: UILabel!
    @IBOutlet weak var powerView: PowerProgressView!
    @IBOutlet weak var socketCollectionView: UICollectionView!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        powerView.setCircleColor(color: UIColor.purple)
        powerView.animateToProgress(progress: 0)
    }


    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "info"{
            let vc = segue.destination as? FXDeviceInfoTableViewController
            vc?.deviceModel = self.deviceModel
        }
        
        if let vc = segue.destination as? TCSocketViewController,let sender = sender as? UIButton{
            vc.plug = sender.tag
            vc.title = self.deviceModel.sockets[sender.tag].sockeTtitle
            vc.deviceModel = self.deviceModel
        }
        
    }
    
    
    fileprivate func plugMessageReload(message:JSON){
        if let string = message.rawString(),string.contains("plug") == false{
            return
        }
        if let plug_0 = message["plug_0"].dictionary{
            self.deviceModel.sockets[0].isOn = plug_0["on"]?.boolValue ?? false
            self.deviceModel.sockets[0].sockeTtitle =  plug_0["setting"]?.dictionaryValue["name"]?.stringValue ?? self.deviceModel.sockets[0].sockeTtitle      }
        if let plug_1 = message["plug_1"].dictionary{
            self.deviceModel.sockets[1].isOn = plug_1["on"]?.boolValue ?? false
            self.deviceModel.sockets[1].sockeTtitle =  plug_1["setting"]?.dictionaryValue["name"]?.stringValue ?? self.deviceModel.sockets[1].sockeTtitle       }
        if let plug_2 = message["plug_2"].dictionary{
            self.deviceModel.sockets[2].isOn = plug_2["on"]?.boolValue ?? false
            self.deviceModel.sockets[2].sockeTtitle =  plug_2["setting"]?.dictionaryValue["name"]?.stringValue ?? self.deviceModel.sockets[2].sockeTtitle      }
        if let plug_3 = message["plug_3"].dictionary{
            self.deviceModel.sockets[3].isOn = plug_3["on"]?.boolValue ?? false
            self.deviceModel.sockets[3].sockeTtitle =  plug_3["setting"]?.dictionaryValue["name"]?.stringValue ?? self.deviceModel.sockets[3].sockeTtitle      }
        if let plug_4 = message["plug_4"].dictionary{
            self.deviceModel.sockets[4].isOn = plug_4["on"]?.boolValue ?? false
            self.deviceModel.sockets[4].sockeTtitle =  plug_4["setting"]?.dictionaryValue["name"]?.stringValue ?? self.deviceModel.sockets[4].sockeTtitle      }
        if let plug_5 = message["plug_5"].dictionary{
            self.deviceModel.sockets[5].isOn = plug_5["on"]?.boolValue ?? false
            self.deviceModel.sockets[5].sockeTtitle =  plug_5["setting"]?.dictionaryValue["name"]?.stringValue ?? self.deviceModel.sockets[5].sockeTtitle      }
        if let version = message["version"].string{
            self.deviceModel.version = version
        }
        if let mqtt_uri = message["setting"]["mqtt_uri"].string{
            self.deviceModel.host = mqtt_uri
        }
        if let mqtt_port = message["setting"]["mqtt_port"].int{
            self.deviceModel.port = mqtt_port
        }
        if let mqtt_user = message["setting"]["mqtt_user"].string{
            self.deviceModel.username = mqtt_user
        }
        if let mqtt_password = message["setting"]["mqtt_password"].string{
            self.deviceModel.password = mqtt_password
        }
        //更新这个设备的信息
        self.deviceModel.name = message["name"].stringValue
        self.deviceModel.clientId = self.deviceModel.mac
        TCSQLManager.updateTCDevice(self.deviceModel)
        self.socketCollectionView.reloadData()
//        print("⚠️\(self.deviceModel.name)设备状态更新")
    }
    
    
    override func DeviceServiceReceivedMessage(message: Data) {
        DispatchQueue.main.async {
            let messageJSON = try! JSON(data: message)
            if messageJSON["mac"].stringValue != self.deviceModel.mac{
                return
            }
            let power = messageJSON["power"].floatValue
            if power > 0 {
                self.powerView.animateToProgress(progress: 1/2500 * power)
                self.powerLabel.text = "\(power)W";
                return
            }
            if let ip = messageJSON["ip"].string{
                self.deviceModel.ip = ip
            }
            self.plugMessageReload(message: messageJSON)
        }
        super.DeviceServiceReceivedMessage(message: message)
    }
    
    override func DeviceServiceUnSubscribe(topic: String) {
        print("退订成功! \(topic)")
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
        item.moreButton.tag = indexPath.row
        return item
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = self.view.frame.width / 3
        return CGSize(width: width, height: width)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if #available(iOS 10.0, *) {
            let impactFeedBack = UIImpactFeedbackGenerator(style: .light)
            impactFeedBack.prepare()
            impactFeedBack.impactOccurred()
        }else{
            AudioServicesPlaySystemSound(1519);
        }
        let model = self.deviceModel.sockets[indexPath.row]
        APIServiceManager.share.switchTC1Device(state: !model.isOn, index: indexPath.row)
    }
    
    
}
