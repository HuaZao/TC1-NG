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
import AMapLocationKit

let apiHost = "https://tq.miyauu.com"

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

    private var speed = 0
    fileprivate let locationManager = AMapLocationManager()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        self.fanSetViewLeftConstraint.constant = self.view.bounds.width
        self.reloadCacheData()
        self.getWeather()
    }
    
    fileprivate func reloadCacheData(){
        guard let extensionVlaue = self.deviceModel.extension as? [String:[String:String]] else{
            return
        }
        guard let weather_now = extensionVlaue["weather_now"] else{
            return
        }
        self.weatherNowView.reloadWeatherNowinfo(weather_now)
        if let wea = weather_now["weather"]{
            print("当前天气 \(wea)")
            if wea.contains("云") || wea.contains("阴"){
                self.weatherBg.image = #imageLiteral(resourceName: "多云")
            }else if wea.contains("雨"){
                self.weatherBg.image = #imageLiteral(resourceName: "雨")
            }else if wea.contains("晴"){
                self.weatherBg.image = #imageLiteral(resourceName: "晴")
            }else if wea.contains("风"){
                self.weatherBg.image = #imageLiteral(resourceName: "风")
            }else if wea.contains("雾"){
                self.weatherBg.image = #imageLiteral(resourceName: "雾霾")
            }else if wea.contains("雪"){
                self.weatherBg.image = #imageLiteral(resourceName: "雪")
            }else {
                self.weatherBg.image = #imageLiteral(resourceName: "默认")
            }
        }
        guard let weather_aqi = extensionVlaue["weather_aqi"] else{
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


extension A1DeviceMainViewController{
    
    fileprivate func getWeather(){
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.locationTimeout = 2
        locationManager.reGeocodeTimeout = 2
        locationManager.requestLocation(withReGeocode: true, completionBlock: { [weak self] (location: CLLocation?, reGeocode: AMapLocationReGeocode?, error: Error?) in
            if let reGeocode = reGeocode {
                let freeWeatherApi = URL(string: apiHost + "/api/v2/weather/index")!
                freeWeatherApi.requestJSON(params: ["app_id":"10001","app_version":"1.1.6","astro":"1","gd_code":reGeocode.adcode ?? "440106","astro_type":"1","city_en":reGeocode.city ?? "广州市"], callBack: { (json) in
                    guard let weather = json["data"].dictionaryValue["weather"]?.dictionaryValue else {
                        return
                    }
                    guard let current = weather["current"]?.arrayValue.first else {
                        return
                    }
                    guard let nowWeather = current["weather_now"].dictionaryObject?.mapValues({"\($0)"}) else{
                        return
                    }
                    self?.deviceModel.extension["weather_now"] = nowWeather
                    self?.weatherNowView.reloadWeatherNowinfo(nowWeather)
                    guard let weather_aqi = current["weather_aqi"].dictionaryObject?.mapValues({"\($0)"})else{
                        return
                    }
                    self?.deviceModel.extension["weather_aqi"] = weather_aqi
                    self?.weatherAqiView.reloadWeatherAqinfo(weather_aqi, nowWeather)
                    print(JSON(self?.deviceModel.extension).description)
                    self?.deviceModel.updateToDB()
                })
            }
        })
    }
    
   
    
}

