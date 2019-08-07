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
    private var chartDatasourceCount = 0
    private var powerEntries = [ChartDataEntry]()
    private var voltageEntries = [ChartDataEntry]()
    private var ampereEntries = [ChartDataEntry]()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.initChart()
       
    }
    
    private func initChart(){
        self.chartView.noDataText = "暂无功率数据"
        self.chartView.scaleXEnabled = false //允取消X轴缩放
        self.chartView.scaleYEnabled = false //取消Y轴缩放
        self.chartView.doubleTapToZoomEnabled = false //双击缩放
        self.chartView.xAxis.drawGridLinesEnabled = false
        self.chartView.leftAxis.drawLabelsEnabled = false
        self.chartView.leftAxis.drawAxisLineEnabled = false //不显示右侧Y轴
        self.chartView.rightAxis.drawLabelsEnabled = false //不绘制右侧Y轴文字
        self.chartView.rightAxis.drawAxisLineEnabled = false //不显示右侧Y轴
        let limitLine1 = ChartLimitLine(limit: 3000, label: "最大功率")
        chartView.leftAxis.addLimitLine(limitLine1)
        
    }

    private func updateChartData(powerValue:Double,voltageValue:Double = 0.00,ampereVlaue:Double = 0.00) {
        if self.powerEntries.count > 30 {
            self.powerEntries.removeFirst()
        }else{
            chartView.xAxis.resetCustomAxisMax()
            chartView.xAxis.resetCustomAxisMin()
        }
        self.chartDatasourceCount = self.chartDatasourceCount + 1
        self.chartView.setVisibleXRangeMaximum(10)
        var chartData:LineChartData!
        var chartDataSet = [IChartDataSet]()
        let powerEntry = ChartDataEntry(x: Double(self.chartDatasourceCount), y: powerValue)
        self.powerEntries.append(powerEntry)
        let powerChartData = self.initLineChartData(dataSource: self.powerEntries, describe: "功率", color: ChartColorTemplates.colorful()[3])
        powerChartData.drawFilledEnabled = true //开启填充色绘制
        powerChartData.fillColor = .orange  //设置填充色
        powerChartData.fillAlpha = 0.5 //设置填充色透明度
        
        let voltageEntry = ChartDataEntry(x: Double(self.chartDatasourceCount), y: voltageValue)
        self.voltageEntries.append(voltageEntry)
        let voltageChartData = self.initLineChartData(dataSource: self.voltageEntries, describe: "电压", color: ChartColorTemplates.colorful()[2])
        
        let ampereEntry = ChartDataEntry(x: Double(self.chartDatasourceCount), y: ampereVlaue)
        self.ampereEntries.append(ampereEntry)
        let ampereChartData = self.initLineChartData(dataSource: self.ampereEntries, describe: "安培", color: ChartColorTemplates.colorful()[1])
        
        if powerValue > 0{
            chartDataSet.append(powerChartData)
        }
        if  voltageValue > 0{
            chartDataSet.append(voltageChartData)
        }
        if ampereVlaue > 0{
            chartDataSet.append(ampereChartData)
        }
        chartData = LineChartData(dataSets: chartDataSet)

        chartView.data = chartData
        chartView.data?.notifyDataChanged()
        chartView.notifyDataSetChanged()
        chartView.moveViewToX(Double(self.powerEntries.count - 1))
        
    }
    
    private func initLineChartData(dataSource:[ChartDataEntry],describe:String,color:UIColor)->LineChartDataSet{
        let chartDataSet = LineChartDataSet(entries: dataSource, label: describe)
        chartDataSet.colors = [color]
        chartDataSet.drawCirclesEnabled = false
        chartDataSet.mode = .stepped
        return chartDataSet
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
            self.plugMessageReload(message: messageJSON)
        }
        super.DeviceServiceReceivedMessage(message: message)
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
