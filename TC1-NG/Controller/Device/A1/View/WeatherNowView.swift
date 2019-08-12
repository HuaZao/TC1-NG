//
//  WeatherNowView.swift
//  TC1-NG
//
//  Created by cpu on 2019/8/12.
//  Copyright © 2019 TC1. All rights reserved.
//

import UIKit
import SDWebImage

class WeatherNowView: UIView {

    @IBOutlet weak var weatherTip: UILabel!
    @IBOutlet weak var weatherTemperature: UILabel!
    @IBOutlet weak var weathericonView: UIImageView!
    
    func reloadWeatherNowinfo(_ nowWeather:[String:String]){
        if let weather_img = nowWeather["weather_img"]{
            self.weathericonView.sd_setImage(with: URL(string: apiHost + weather_img))
        }
        if let temp = nowWeather["temp"]{
            let attText =  NSMutableAttributedString(string:temp + "℃")
            attText.addAttributes([NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 65)], range: NSMakeRange(0, temp.count))
            self.weatherTemperature.attributedText = attText
        }
        if let tip = nowWeather["tip"]{
            self.weatherTip.text = tip
        }
    }

}
