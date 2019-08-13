//
//  WeatherAqiView.swift
//  TC1-NG
//
//  Created by cpu on 2019/8/12.
//  Copyright © 2019 TC1. All rights reserved.
//

import UIKit
import SDWebImage

class WeatherAqiView: UIView {
    
    @IBOutlet weak var aqiImage: UIImageView!
    @IBOutlet weak var aqiDescribe: UILabel!
    @IBOutlet weak var aqiHumidity: UILabel!
    @IBOutlet weak var aqiPressure: UILabel!
    @IBOutlet weak var aqiWindDescribe: UILabel!
    

    @IBOutlet weak var aqiCount: UILabel!
    @IBOutlet weak var aqiPM25: UILabel!
    @IBOutlet weak var aqiPM10: UILabel!
    @IBOutlet weak var aqiSo2: UILabel!
    @IBOutlet weak var aqiNo2: UILabel!
    @IBOutlet weak var aqiCo: UILabel!
    @IBOutlet weak var aqiO3: UILabel!

    
    func reloadWeatherAqinfo(_ weatherAqi:[String:String],_ nowWeather:[String:String]){
        if let aqi_image = weatherAqi["aqi_image"]{
            self.aqiImage.sd_setImage(with: URL(string: apiHost + aqi_image))
        }
        if let aqi_text = weatherAqi["aqi_text"]{
           self.aqiDescribe.text = aqi_text
        }
        if let humidity = nowWeather["humidity"]{
            self.aqiHumidity.text = "\(humidity)%"
        }
        if let winddirect = nowWeather["winddirect"],let windpower = nowWeather["windpower"]{
            self.aqiWindDescribe.text = "\(winddirect),\(windpower)级"
        }
        if let pressure = nowWeather["pressure"]{
            self.aqiPressure.text = "\(pressure)hPa"
        }
        
        //AQI
        if let pm25 = weatherAqi["pm25"]{
            self.aqiPM25.text = pm25
        }
        if let o3 = weatherAqi["o3"]{
            self.aqiO3.text = o3
        }
        if let so2 = weatherAqi["so2"]{
            self.aqiSo2.text = so2
        }
        if let co = weatherAqi["co"]{
            self.aqiCo.text = co
        }
        if let pm10 = weatherAqi["pm10"]{
            self.aqiPM10.text = pm10
        }
        if let aqi = weatherAqi["aqi"]{
            self.aqiCount.text = "空气质量指数:\(aqi)"
        }
        if let no2 = weatherAqi["no2"]{
            self.aqiNo2.text = no2
        }
    }

}
