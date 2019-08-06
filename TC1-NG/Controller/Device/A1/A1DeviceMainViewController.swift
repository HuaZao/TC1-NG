//
//  A1DeviceMainViewController.swift
//  TC1-NG
//
//  Created by cpu on 2019/8/5.
//  Copyright © 2019 TC1. All rights reserved.
//

import UIKit
import SwiftyJSON
import PKHUD

class A1DeviceMainViewController: FXDeviceMainViewController {

    @IBOutlet weak var switchButton: A1Button!
    @IBOutlet weak var fanSpeedButton: A1Button!
    @IBOutlet weak var maxSpeedButton: A1Button!
    @IBOutlet weak var sleepSpeedButton: A1Button!
    @IBOutlet weak var taskButton: A1Button!
    @IBOutlet weak var weatherBg: UIImageView!
    @IBOutlet weak var fanSetViewLeftConstraint: NSLayoutConstraint!
    @IBOutlet weak var fanSpeedLabel: UILabel!
    @IBOutlet weak var fanSpeedSlider: UISlider!
    
    private var speed = 0
    override func viewDidLoad() {
        self.fanSetViewLeftConstraint.constant = self.view.bounds.width
        super.viewDidLoad()
        self.getWeather()
    }
    
    private func getWeather(){
        let freeWeatherApi = URL(string: "https://www.tianqiapi.com/api/?version=v6")!
        freeWeatherApi.requestJSON { (json) in
             let wea = json["wea"].stringValue
            if wea.contains("云"){
                self.weatherBg.image = #imageLiteral(resourceName: "多云")
            }else if wea.contains("雨"){
                self.weatherBg.image = #imageLiteral(resourceName: "雨")
            }else if wea.contains("晴"){
                self.weatherBg.image = #imageLiteral(resourceName: "晴")
            }else if wea.contains("风"){
                self.weatherBg.image = #imageLiteral(resourceName: "风")
            }else if wea.contains("雾霾"){
                self.weatherBg.image = #imageLiteral(resourceName: "雾霾")
            }else if wea.contains("雪"){
                self.weatherBg.image = #imageLiteral(resourceName: "雪")
            }else {
                self.weatherBg.image = #imageLiteral(resourceName: "默认")
            }
        }
    }
    
    @IBAction func fanSpeedValueChanged(_ sender: UISlider) {
        let value = Int(sender.value)
        self.setA1FanSpeed(value)
        self.fanSpeedLabel.text = "当前风速:\(value)"
    }
    
    @IBAction func dimissFanSetViewAction(_ sender: Any) {
        self.fanSetViewLeftConstraint.constant = self.view.bounds.width
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    @IBAction func switchAction(_ sender: A1Button) {
        if sender.isSelected {
            self.maxSpeedButton.isSelected = false
            self.sleepSpeedButton.isSelected = false
            APIServiceManager.share.publishMessage(["mac":self.deviceModel.mac ,"on":0,"speed":0])
        }else{
            self.setA1FanSpeed(50)
        }
        sender.isSelected = !sender.isSelected
        self.fanSpeedButton.isSelected = sender.isSelected
    }
    
    @IBAction func fanSpeedAction(_ sender: A1Button) {
        self.fanSetViewLeftConstraint.constant = 0
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    @IBAction func maxSpeedAction(_ sender: A1Button) {
        self.sleepSpeedButton.isSelected = false
        sender.isSelected = true
        self.setA1FanSpeed(100)
    }
    
    @IBAction func sleepSpeedAction(_ sender: A1Button) {
        self.maxSpeedButton.isSelected = false
        sender.isSelected = true
        self.setA1FanSpeed(20)
    }
    
    @IBAction func tsakAction(_ sender: A1Button) {
        HUD.flash(HUDContentType.label("开发中"), delay: 2.0)
    }
    
    private func setA1FanSpeed(_ value:Int){
        APIServiceManager.share.publishMessage(["mac":self.deviceModel.mac ,"on":1,"speed":value])
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
    
    
    override func DeviceServiceReceivedMessage(message: Data) {
        DispatchQueue.main.async {
            let messageJSON = try! JSON(data: message)
            if messageJSON["mac"].stringValue != self.deviceModel.mac{
                return
            }
            if let ip = messageJSON["ip"].string{
                self.deviceModel.ip = ip
            }
            let on = messageJSON["on"].intValue
            self.switchButton.isSelected = (on == 1)
            self.speed = messageJSON["speed"].intValue
            if self.speed > 0{
                self.fanSpeedButton.setTitle("风速:\(self.speed)", for: .normal)
            }else{
                self.fanSpeedButton.setTitle("风速", for: .normal)
            }
            self.fanSpeedButton.isSelected = (self.speed > 0)
            self.maxSpeedButton.isSelected = (self.speed == 100)
            self.sleepSpeedButton.isSelected = (self.speed == 20)
        }
        super.DeviceServiceReceivedMessage(message: message)
    }


}
