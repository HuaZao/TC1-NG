//
//  WeatherTool.swift
//  TC1-NG
//
//  Created by cpu on 2019/10/15.
//  Copyright © 2019 TC1. All rights reserved.
//

import UIKit
#if os(iOS)
import AMapLocationKit
#else

#endif
let apiHost = "https://tq.miyauu.com"

class WeatherTool: NSObject {
    
    static let share = WeatherTool()
    
    #if os(iOS)
    fileprivate let locationManager = AMapLocationManager()
    #endif
    
    func getWeather(weatherBlock:@escaping(_ nowWeather:[String:String],_ weatherAqi:[String:String],_ cityName:String)->Void){
           #if os(iOS)
           locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
           locationManager.locationTimeout = 2
           locationManager.reGeocodeTimeout = 2
           locationManager.requestLocation(withReGeocode: true, completionBlock: { (location: CLLocation?, reGeocode: AMapLocationReGeocode?, error: Error?) in
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
                       guard let weather_aqi = current["weather_aqi"].dictionaryObject?.mapValues({"\($0)"})else{
                           return
                       }
                       weatherBlock(nowWeather,weather_aqi,"\(reGeocode.province ?? "广东省")-\(reGeocode.city ?? "广州市")")
                   })
               }
           })
           #endif
       }
    

}
