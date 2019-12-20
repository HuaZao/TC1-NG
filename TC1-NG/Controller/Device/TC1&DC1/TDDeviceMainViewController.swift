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
import Charts

class TDDeviceMainViewController: FXDeviceMainViewController {
    
    @IBOutlet weak var chartContainerView: UIView!
    @IBOutlet weak var socketCollectionView: UICollectionView!
    @IBOutlet weak var chartView:LineChartView!
    @IBOutlet weak var nowDataView: UIView!
    
    private var chartPowerCount = 0
    private var chartVoltageCount = 0
    private var chartAmpereCount = 0

    private var powerEntries = [ChartDataEntry]()
    private var voltageEntries = [ChartDataEntry]()
    private var ampereEntries = [ChartDataEntry]()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.initChart()
       
    }
    
    private func initChart(){
        self.chartView.noDataText = ""
        self.chartView.scaleXEnabled = false
        self.chartView.scaleYEnabled = false
        self.chartView.doubleTapToZoomEnabled = false
        self.chartView.xAxis.drawGridLinesEnabled = false
        self.chartView.xAxis.drawAxisLineEnabled = false
        self.chartView.xAxis.drawLabelsEnabled = false
        self.chartView.leftAxis.drawLabelsEnabled = false
        self.chartView.leftAxis.drawGridLinesEnabled = false
        self.chartView.leftAxis.drawAxisLineEnabled = false
        self.chartView.rightAxis.drawLabelsEnabled = false
        self.chartView.rightAxis.drawGridLinesEnabled = false
        self.chartView.rightAxis.drawAxisLineEnabled = false

        let limitLine1 = ChartLimitLine(limit: 2500, label: "最大功率")
        chartView.leftAxis.addLimitLine(limitLine1)
        
    }

    private func updateChartData(powerValue:Double,voltageValue:Double = 0.00,ampereVlaue:Double = 0.00) {
        self.nowDataView.isHidden = true
        self.chartView.autoScaleMinMaxEnabled = true
        self.chartView.setVisibleXRangeMaximum(10)
        var chartData:LineChartData!
        var chartDataSet = [IChartDataSet]()
        let powerEntry = ChartDataEntry(x: Double(self.chartPowerCount), y: powerValue)
        self.powerEntries.append(powerEntry)
        let powerChartData = self.initLineChartData(dataSource: self.powerEntries, describe: "功率", color: ChartColorTemplates.colorful()[3])
        powerChartData.drawFilledEnabled = true //开启填充色绘制
        powerChartData.fillColor = .orange  //设置填充色
        powerChartData.fillAlpha = 0.5 //设置填充色透明度
        
        let voltageEntry = ChartDataEntry(x: Double(self.chartVoltageCount), y: voltageValue)
        self.voltageEntries.append(voltageEntry)
        let voltageChartData = self.initLineChartData(dataSource: self.voltageEntries, describe: "电压", color: ChartColorTemplates.colorful()[2])
        
        let ampereEntry = ChartDataEntry(x: Double(self.chartAmpereCount), y: ampereVlaue)
        self.ampereEntries.append(ampereEntry)
        let ampereChartData = self.initLineChartData(dataSource: self.ampereEntries, describe: "安培", color: ChartColorTemplates.colorful()[1])
        
        if powerValue > 0{
            self.chartPowerCount = self.chartPowerCount + 1
            chartDataSet.append(powerChartData)
        }
        //如果电压太大,电流和功率太小,曲线图精度会下降,这里调整下电压的显示
        if  voltageValue > 0 && powerValue > 200{
            self.chartVoltageCount = self.chartVoltageCount + 1
            chartDataSet.append(voltageChartData)
        }
        if ampereVlaue > 0{
            self.chartAmpereCount = self.chartAmpereCount + 1
            chartDataSet.append(ampereChartData)
        }
        chartData = LineChartData(dataSets: chartDataSet)

        chartView.data = chartData
        chartView.data?.notifyDataChanged()
        chartView.notifyDataSetChanged()
        chartView.moveViewToX(Double(self.chartPowerCount))
    }
    
    private func initLineChartData(dataSource:[ChartDataEntry],describe:String,color:UIColor)->LineChartDataSet{
        let chartDataSet = LineChartDataSet(entries: dataSource, label: describe)
        chartDataSet.colors = [color]
        chartDataSet.drawCirclesEnabled = false
        chartDataSet.mode = .horizontalBezier
        chartDataSet.highlightEnabled = false
        return chartDataSet
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
    
    override func updateDevice(message: JSON) {
        if let plug_0 = message["plug_0"].dictionary{
            self.needUpdate = true
            self.deviceModel.sockets[0].isOn = plug_0["on"]?.boolValue ?? false
            self.deviceModel.sockets[0].sockeTitle =  plug_0["setting"]?.dictionaryValue["name"]?.stringValue ?? self.deviceModel.sockets[0].sockeTitle      }
        if let plug_1 = message["plug_1"].dictionary{
            self.needUpdate = true
            self.deviceModel.sockets[1].isOn = plug_1["on"]?.boolValue ?? false
            self.deviceModel.sockets[1].sockeTitle =  plug_1["setting"]?.dictionaryValue["name"]?.stringValue ?? self.deviceModel.sockets[1].sockeTitle       }
        if let plug_2 = message["plug_2"].dictionary{
            self.needUpdate = true
            self.deviceModel.sockets[2].isOn = plug_2["on"]?.boolValue ?? false
            self.deviceModel.sockets[2].sockeTitle =  plug_2["setting"]?.dictionaryValue["name"]?.stringValue ?? self.deviceModel.sockets[2].sockeTitle      }
        if let plug_3 = message["plug_3"].dictionary{
            self.needUpdate = true
            self.deviceModel.sockets[3].isOn = plug_3["on"]?.boolValue ?? false
            self.deviceModel.sockets[3].sockeTitle =  plug_3["setting"]?.dictionaryValue["name"]?.stringValue ?? self.deviceModel.sockets[3].sockeTitle      }
        if let plug_4 = message["plug_4"].dictionary{
            self.needUpdate = true
            self.deviceModel.sockets[4].isOn = plug_4["on"]?.boolValue ?? false
            self.deviceModel.sockets[4].sockeTitle =  plug_4["setting"]?.dictionaryValue["name"]?.stringValue ?? self.deviceModel.sockets[4].sockeTitle      }
        if let plug_5 = message["plug_5"].dictionary{
            self.needUpdate = true
            self.deviceModel.sockets[5].isOn = plug_5["on"]?.boolValue ?? false
            self.deviceModel.sockets[5].sockeTitle =  plug_5["setting"]?.dictionaryValue["name"]?.stringValue ?? self.deviceModel.sockets[5].sockeTitle      }
        if self.needUpdate{
            self.socketCollectionView.reloadData()
        }
        super.updateDevice(message: message)
    }
    
    
    override func DeviceServiceReceivedMessage(message: Data) {
        super.DeviceServiceReceivedMessage(message: message)
        DispatchQueue.main.async {
            let messageJSON = try! JSON(data: message)
            let power = messageJSON["power"].doubleValue
            let voltage = messageJSON["voltage"].doubleValue
            let ampere = messageJSON["current"].doubleValue
            if power > 0{
                self.updateChartData(powerValue: power, voltageValue: voltage, ampereVlaue: ampere)
                return
            }
            if let ip = messageJSON["ip"].string{
                self.deviceModel.ip = ip
            }
        }
    }
    
    override func DeviceServiceUnSubscribe(topic: String) {
        print("退订成功! \(topic)")
    }
    
    
    
}


extension TDDeviceMainViewController:UICollectionViewDelegateFlowLayout,UICollectionViewDelegate,UICollectionViewDataSource{
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.deviceModel.sockets.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let item = collectionView.dequeueReusableCell(withReuseIdentifier: "socketItem", for: indexPath) as! TCSocketItem
        item.titleLabel.text = self.deviceModel.sockets[indexPath.row].sockeTitle
        item.socketButton.isOn = self.deviceModel.sockets[indexPath.row].isOn
        item.moreButton.tag = indexPath.row
        return item
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if self.deviceModel.type == .TC1{
            let width = Int(self.view.frame.width / 3)
            return CGSize(width: width, height: width)
        }else if self.deviceModel.type == .DC1{
            let width = Int(self.view.frame.width / 3)
            if indexPath.item == 0{
                return CGSize(width: Int(self.view.frame.width), height: width)
            }else{
                return CGSize(width: width, height: width)
            }
        }else{
            return CGSize(width: 0, height: 0)
        }
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
