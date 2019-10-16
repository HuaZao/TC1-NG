//
//  M1DeviceMainViewController.swift
//  TC1-NG
//
//  Created by cpu on 2019/10/14.
//  Copyright © 2019 TC1. All rights reserved.
//

import UIKit
import Charts
import SwiftyJSON

class M1DeviceMainViewController: FXDeviceMainViewController {
    //甲醛,PM2.5
    @IBOutlet weak var PCView: LineChartView!
    //温度,湿度
    @IBOutlet weak var THView: LineChartView!
    
    @IBOutlet weak var weatherAqiView: WeatherAqiView!
    @IBOutlet weak var weatherBg: UIImageView!
    
    private var pm25Entries = [ChartDataEntry]()
    private var choEntries = [ChartDataEntry]()
    private var tempEntries = [ChartDataEntry]()
    private var humEntries = [ChartDataEntry]()
    
    private var chartPm25Count = 0
    private var chartChoCount = 0
    private var chartTempCount = 0
    private var chartHumCount = 0
    
    private var weatherView = WHWeatherView(frame: UIScreen.main.bounds)

    override func viewDidLoad() {
        super.viewDidLoad()
        self.weatherBg.addSubview(self.weatherView)
        self.reloadCacheData()
        self.initChart()
        WeatherTool.share.getWeather { [weak self] (nowWeather, weather_aqi,cityName) in
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
    
    private func initChart(){
        self.PCView.noDataText = ""
        self.PCView.scaleXEnabled = false
        self.PCView.scaleYEnabled = false
        self.PCView.doubleTapToZoomEnabled = false
        self.PCView.xAxis.drawGridLinesEnabled = false
        self.PCView.xAxis.drawAxisLineEnabled = false
        self.PCView.xAxis.drawLabelsEnabled = false
        self.PCView.leftAxis.drawLabelsEnabled = false
        self.PCView.leftAxis.drawGridLinesEnabled = false
        self.PCView.leftAxis.drawAxisLineEnabled = false
        self.PCView.rightAxis.drawLabelsEnabled = false
        self.PCView.rightAxis.drawGridLinesEnabled = false
        self.PCView.rightAxis.drawAxisLineEnabled = false
        
        self.THView.noDataText = ""
        self.THView.scaleXEnabled = false
        self.THView.scaleYEnabled = false
        self.THView.doubleTapToZoomEnabled = false
        self.THView.xAxis.drawGridLinesEnabled = false
        self.THView.xAxis.drawAxisLineEnabled = false
        self.THView.xAxis.drawLabelsEnabled = false
        self.THView.leftAxis.drawLabelsEnabled = false
        self.THView.leftAxis.drawGridLinesEnabled = false
        self.THView.leftAxis.drawAxisLineEnabled = false
        self.THView.rightAxis.drawLabelsEnabled = false
        self.THView.rightAxis.drawGridLinesEnabled = false
        self.THView.rightAxis.drawAxisLineEnabled = false
    }
    
    fileprivate func reloadCacheData(){
        guard let extensionVlaue = self.deviceModel.extension as? [String:Any] else{
            return
        }
        guard let weather_now = extensionVlaue["weather_now"] as? [String:String] else{
            return
        }
        guard let weather_aqi = extensionVlaue["weather_aqi"] as? [String:String] else{
            return
        }
        self.weatherAqiView.reloadWeatherAqinfo(weather_aqi,weather_now)
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
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
           if segue.identifier == "info"{
               let vc = segue.destination as? FXDeviceInfoTableViewController
               vc?.deviceModel = self.deviceModel
           }
       }
    
    
    private func updatePCChartData(pm25:Double,cho:Double) {
        self.PCView.autoScaleMinMaxEnabled = true
        self.PCView.setVisibleXRangeMaximum(10)
        var chartData:LineChartData!
        var chartDataSet = [IChartDataSet]()
        let pm25Entry = ChartDataEntry(x: Double(self.chartPm25Count), y: pm25)
        self.pm25Entries.append(pm25Entry)
        let pm25ChartData = self.initLineChartData(dataSource: self.pm25Entries, describe: "PM2.5(μg/m³)", color: ChartColorTemplates.colorful()[3])
        chartDataSet.append(pm25ChartData)
        
        let choEntry = ChartDataEntry(x: Double(self.chartChoCount), y: cho)
        self.choEntries.append(choEntry)
        let choChartData = self.initLineChartData(dataSource: self.choEntries, describe: "甲醛(mg/m³)", color: ChartColorTemplates.colorful()[2])
        chartDataSet.append(choChartData)

        chartData = LineChartData(dataSets: chartDataSet)
        PCView.data = chartData
        PCView.data?.notifyDataChanged()
        PCView.notifyDataSetChanged()
        PCView.moveViewToX(Double(self.chartPm25Count))
    }
    
    private func updateTHChartData(temp:Double,hum:Double) {
        self.PCView.autoScaleMinMaxEnabled = true
        self.PCView.setVisibleXRangeMaximum(10)
        var chartData:LineChartData!
        var chartDataSet = [IChartDataSet]()
        let tempEntry = ChartDataEntry(x: Double(self.chartTempCount), y: temp)
        self.tempEntries.append(tempEntry)
        let tempChartData = self.initLineChartData(dataSource: self.tempEntries, describe: "温度(°C)", color: ChartColorTemplates.colorful()[3])
        chartDataSet.append(tempChartData)
        
        let humEntry = ChartDataEntry(x: Double(self.chartHumCount), y: hum)
        self.humEntries.append(humEntry)
        let humChartData = self.initLineChartData(dataSource: self.humEntries, describe: "湿度(%)", color: ChartColorTemplates.colorful()[2])
        chartDataSet.append(humChartData)

        chartData = LineChartData(dataSets: chartDataSet)
        PCView.data = chartData
        PCView.data?.notifyDataChanged()
        PCView.notifyDataSetChanged()
        PCView.moveViewToX(Double(self.chartPm25Count))
    }
    
    private func initLineChartData(dataSource:[ChartDataEntry],describe:String,color:UIColor)->LineChartDataSet{
        let chartDataSet = LineChartDataSet(entries: dataSource, label: describe)
        chartDataSet.colors = [color]
        chartDataSet.drawCirclesEnabled = false
        chartDataSet.mode = .horizontalBezier
        return chartDataSet
    }
    
    override func DeviceServiceReceivedMessage(message: Data) {
        super.DeviceServiceReceivedMessage(message: message)
        DispatchQueue.main.async {
            let messageJSON = try! JSON(data: message)
            let pm25 = messageJSON["PM25"].doubleValue
            let formaldehyde = messageJSON["formaldehyde"].doubleValue
            self.updatePCChartData(pm25: pm25, cho: formaldehyde)
            let temperature = messageJSON["temperature"].doubleValue
            let humidity = messageJSON["humidity"].doubleValue
            self.updateTHChartData(temp: temperature, hum: humidity)
        }
    }
    
}




