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
    @IBOutlet weak var PView: LineChartView!
    
    @IBOutlet weak var CView: LineChartView!

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
        self.deviceModel.isActivate = true
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
        self.PView.noDataText = ""
        self.PView.scaleXEnabled = false
        self.PView.scaleYEnabled = false
        self.PView.doubleTapToZoomEnabled = false
        self.PView.leftAxis.enabled = false
        self.PView.rightAxis.enabled = false
        self.PView.xAxis.enabled = false
        
        self.CView.noDataText = ""
        self.CView.scaleXEnabled = false
        self.CView.scaleYEnabled = false
        self.CView.doubleTapToZoomEnabled = false
        self.CView.leftAxis.enabled = false
        self.CView.rightAxis.enabled = false
        self.CView.xAxis.enabled = false
        
        self.THView.noDataText = ""
        self.THView.scaleXEnabled = false
        self.THView.scaleYEnabled = false
        self.THView.doubleTapToZoomEnabled = false
        self.THView.leftAxis.enabled = false
        self.THView.rightAxis.enabled = false
        self.THView.xAxis.enabled = false
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
    
    
    private func updatePChartData(pm25:Double) {
        self.PView.autoScaleMinMaxEnabled = true
        self.PView.setVisibleXRangeMaximum(5)

        var chartData:LineChartData!
        var chartDataSet = [IChartDataSet]()
        let pm25Entry = ChartDataEntry(x: Double(self.chartPm25Count), y: pm25)
        self.pm25Entries.append(pm25Entry)
        let pm25ChartData = self.initLineChartData(dataSource: self.pm25Entries, describe: "PM2.5(μg/m³)", color: ChartColorTemplates.material()[0])
        self.chartPm25Count = self.chartPm25Count + 1
        chartDataSet.append(pm25ChartData)
        
        chartData = LineChartData(dataSets: chartDataSet)
        PView.data = chartData
        PView.data?.notifyDataChanged()
        PView.notifyDataSetChanged()
        PView.moveViewToX(Double(self.chartPm25Count))
    }
    
    private func updateCChartData(cho:Double) {
        self.CView.autoScaleMinMaxEnabled = true
        self.CView.setVisibleXRangeMaximum(5)
        
        var chartData:LineChartData!
        var chartDataSet = [IChartDataSet]()
        let choEntry = ChartDataEntry(x: Double(self.chartChoCount), y:cho)
        self.choEntries.append(choEntry)
        let choChartData = self.initLineChartData(dataSource: self.choEntries, describe: "甲醛(mg/m³)", color: ChartColorTemplates.material()[1])
        self.chartChoCount = self.chartChoCount + 1
        chartDataSet.append(choChartData)

        chartData = LineChartData(dataSets: chartDataSet)
        CView.data = chartData
        CView.data?.notifyDataChanged()
        CView.notifyDataSetChanged()
        CView.moveViewToX(Double(self.chartChoCount))
    }
    
    private func updateTHChartData(temp:Double,hum:Double) {
        self.THView.autoScaleMinMaxEnabled = true
        self.THView.setVisibleXRangeMaximum(5)
        var chartData:LineChartData!
        var chartDataSet = [IChartDataSet]()
        let tempEntry = ChartDataEntry(x: Double(self.chartTempCount), y: temp)
        self.tempEntries.append(tempEntry)
        let tempChartData = self.initLineChartData(dataSource: self.tempEntries, describe: "温度(°C)", color: ChartColorTemplates.material()[2])
        self.chartTempCount = self.chartTempCount + 1
        chartDataSet.append(tempChartData)
        
        let humEntry = ChartDataEntry(x: Double(self.chartHumCount), y: hum)
        self.humEntries.append(humEntry)
        let humChartData = self.initLineChartData(dataSource: self.humEntries, describe: "湿度(%)", color: ChartColorTemplates.material()[3])
        self.chartHumCount = self.chartHumCount + 1
        chartDataSet.append(humChartData)

        chartData = LineChartData(dataSets: chartDataSet)
        THView.data = chartData
        THView.data?.notifyDataChanged()
        THView.notifyDataSetChanged()
        THView.moveViewToX(Double(self.chartTempCount))
    }
    
    private func initLineChartData(dataSource:[ChartDataEntry],describe:String,color:UIColor)->LineChartDataSet{
        let chartDataSet = LineChartDataSet(entries: dataSource, label: describe)
        chartDataSet.colors = [color]
        chartDataSet.drawCirclesEnabled = false
        chartDataSet.mode = .linear
        chartDataSet.highlightEnabled = false
        return chartDataSet
    }
    
    override func DeviceServiceReceivedMessage(message: Data) {
        super.DeviceServiceReceivedMessage(message: message)
        DispatchQueue.main.async {
            let messageJSON = try! JSON(data: message)
            let pm25 = messageJSON["PM25"].doubleValue
            let formaldehyde = messageJSON["formaldehyde"].doubleValue
            if pm25 > 0 {
                self.updatePChartData(pm25: pm25)
            }
            if formaldehyde > 0{
                self.updateCChartData(cho: formaldehyde)
            }
            let temperature = messageJSON["temperature"].doubleValue
            let humidity = messageJSON["humidity"].doubleValue
            if temperature > 0 && humidity > 0{
                self.updateTHChartData(temp: temperature, hum: humidity)
            }
        }
    }
    
}




