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
    
    @IBOutlet weak var weatherNowView: WeatherNowView!
    @IBOutlet weak var weatherAqiView: WeatherAqiView!

    private var weatherView = WHWeatherView(frame: UIScreen.main.bounds)
    
    private var speed = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        self.weatherBg.addSubview(self.weatherView)
        self.fanSetViewLeftConstraint.constant = self.view.bounds.width
        self.reloadCacheData()
        WeatherTool.share.getWeather { [weak self] (nowWeather, weather_aqi,cityName) in
            self?.weatherNowView.reloadWeatherNowinfo(nowWeather)
            self?.weatherAqiView.reloadWeatherAqinfo(weather_aqi, nowWeather)
            self?.deviceModel.extension["weather_now"] = nowWeather
            self?.deviceModel.extension["weather_aqi"] = weather_aqi
            self?.deviceModel.extension["weather_city"] = cityName
            self?.deviceModel.updateToDB()
            if let wea = nowWeather["weather"]{
                if wea.contains("云") || wea.contains("阴"){
                   self?.weatherView.showWeatherAnimation(with: .clound)
                }else if wea.contains("雨"){
                    self?.weatherView.showWeatherAnimation(with: .rain)
                }else if wea.contains("晴"){
                    self?.weatherView.showWeatherAnimation(with: .sun)
                }else if wea.contains("风"){
                    self?.weatherView.showWeatherAnimation(with: .clound)
                }else if wea.contains("雾"){
                    self?.weatherView.showWeatherAnimation(with: .clound)
                }else if wea.contains("雪"){
                    self?.weatherView.showWeatherAnimation(with: .snow)
                }else {
                    self?.weatherView.showWeatherAnimation(with: .clound)
                }
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.weatherView.removeFromSuperview()
    }
    
    fileprivate func reloadCacheData(){
        guard let extensionVlaue = self.deviceModel.extension as? [String:Any] else{
            return
        }
        guard let weather_now = extensionVlaue["weather_now"] as? [String:String] else{
            return
        }
        if let weather_city = extensionVlaue["weather_city"] as? String{
           self.weatherNowView.weatherCitylabel.text = weather_city
        }

        self.weatherNowView.reloadWeatherNowinfo(weather_now)
        if let wea = weather_now["weather"]{
            if wea.contains("云") || wea.contains("阴"){
               self.weatherView.showWeatherAnimation(with: .clound)
            }else if wea.contains("雨"){
                self.weatherView.showWeatherAnimation(with: .rain)
            }else if wea.contains("晴"){
                self.weatherView.showWeatherAnimation(with: .sun)
            }else if wea.contains("风"){
                self.weatherView.showWeatherAnimation(with: .clound)
            }else if wea.contains("雾"){
                self.weatherView.showWeatherAnimation(with: .clound)
            }else if wea.contains("雪"){
                self.weatherView.showWeatherAnimation(with: .snow)
            }else {
                self.weatherView.showWeatherAnimation(with: .clound)
            }
        }
        guard let weather_aqi = extensionVlaue["weather_aqi"] as? [String:String] else{
            return
        }
        self.weatherAqiView.reloadWeatherAqinfo(weather_aqi,weather_now)
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
            vc.title = self.deviceModel.sockets[sender.tag].sockeTitle
            vc.deviceModel = self.deviceModel
        }
        
    }
    
    
    override func DeviceServiceReceivedMessage(message: Data) {
        super.DeviceServiceReceivedMessage(message: message)
        DispatchQueue.main.async {
            let messageJSON = try! JSON(data: message)
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
    }


}
