//
//  TCListViewController.swift
//  TC1-NG
//
//  Created by QAQ on 2019/4/24.
//  Copyright © 2019 TC1. All rights reserved.
//

import UIKit
import SwiftyJSON
import PKHUD

class TCListViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var noDeviceBg: UIImageView!
    fileprivate var netServiceBrowser:NetServiceBrowser?
    fileprivate var serviceDataSource = [NetService]()
    private var dataSource = [TCDeviceModel]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.netServiceBrowser = NetServiceBrowser()
        self.netServiceBrowser?.delegate = self
        self.netServiceBrowser?.schedule(in: RunLoop.main, forMode: .common)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.netServiceBrowser?.searchForServices(ofType: "_easylink._tcp", inDomain: "local")
        self.dataSource = TCSQLManager.queryAllTCDevice()
        self.noDeviceBg.isHidden = !self.dataSource.isEmpty
        self.tableView.reloadData()
    }
    
    private func discoverDevices(){
        APIServiceManager.share.delegate = self
        APIServiceManager.share.connectUDPService()
        APIServiceManager.share.sendDeviceReportCmd()
    }
    
}

extension TCListViewController:APIServiceReceiveDelegate,NetServiceBrowserDelegate,NetServiceDelegate{
    
    func DeviceServiceReceivedMessage(message: Data) {
        let messageJSON = try! JSON(data: message)
        //如果有IP信息,则添加设备!
        let ip = messageJSON["ip"].stringValue
        if ip.count > 0 && !TCSQLManager.deciveisExist(messageJSON["mac"].stringValue) {
            let deviceModel = messageJSON.addDevice()
            DispatchQueue.main.async {
                self.dataSource.append(deviceModel)
                self.noDeviceBg.isHidden = true
                self.tableView.reloadData()
            }
        }
    }
    
    func DeviceServicePublish(messageId: Int) {
        print("消息已经发送--> \(messageId)")
    }
    
    func getIPV4StringfromAddress(address: [Data]) -> String{
        let data = address.first! as NSData;
        var ip1 = UInt8(0)
        data.getBytes(&ip1, range: NSMakeRange(4, 1))
        var ip2 = UInt8(0)
        data.getBytes(&ip2, range: NSMakeRange(5, 1))
        var ip3 = UInt8(0)
        data.getBytes(&ip3, range: NSMakeRange(6, 1))
        var ip4 = UInt8(0)
        data.getBytes(&ip4, range: NSMakeRange(7, 1))
        let ipStr = String(format: "%d.%d.%d.%d",ip1,ip2,ip3,ip4);
        return ipStr;
    }
    
    func netServiceDidResolveAddress(_ sender: NetService) {
        if let TXTRecord = sender.txtRecordData(){
            let serviceInfo = NetService.dictionary(fromTXTRecord:TXTRecord)
            var serviceDic = [String:String]()
            serviceInfo.forEach { dic in
                if let value = String(data: dic.value, encoding: String.Encoding.utf8){
                    serviceDic[dic.key] = value
                }
            }
            if let ipData = sender.addresses,ipData.count > 0{
                serviceDic["IP"] = self.getIPV4StringfromAddress(address: ipData)
            }
            serviceDic["Port"] = "\(sender.port)"
            print("发现设备->\(serviceDic)")
            if var mac = serviceDic["MAC"]{
                mac = mac.replacingOccurrences(of: ":", with: "").lowercased()
                if TCSQLManager.deciveisExist(mac) {
                    print("MAC:\(mac) 设备已存在,跳过添加")
                    return
                }
            }
            if JSON(serviceDic).isA2633063Protocol(){
                self.discoverDevices()
            }
        }
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        self.serviceDataSource.append(service)
        service.delegate = self
        service.resolve(withTimeout: 5.0)
        if !moreComing {
            print("数据全部接受完毕")
        }
    }
    
}


extension TCListViewController:UITableViewDelegate,UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TCCell", for: indexPath) as! TCDeviceCell
        cell.loadDeviceModel(self.dataSource[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let deviceModel = self.dataSource[indexPath.row]
        APIServiceManager.share.closeService()
        switch self.dataSource[indexPath.row].type {
        case .TC1:
            if let vc = UIStoryboard(name: "TCDeviceMain", bundle: nil).instantiateViewController(withIdentifier: "TC1") as? TCDeviceMainViewController{
                vc.deviceModel = deviceModel
                vc.title = deviceModel.name
                self.navigationController?.pushViewController(vc, animated: true)
            }
        case .DC1:
            HUD.flash(.label("DC1开发中"), delay: 2.0)
        case .A1:
            if let vc = UIStoryboard(name: "TCDeviceMain", bundle: nil).instantiateViewController(withIdentifier: "A1") as? A1DeviceMainViewController{
                vc.deviceModel = deviceModel
                vc.title = deviceModel.name
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete{
            let alert = UIAlertController(title: "移除设备", message: "确定要删除此设备?(\(self.dataSource[indexPath.row].name))", preferredStyle: .alert)
            let cancel = UIAlertAction(title: "取消", style: .cancel, handler: nil)
            alert.addAction(cancel)
            let remove = UIAlertAction(title: "确认", style: .destructive) { (_) in
                TCSQLManager.removeTCDevice(self.dataSource[indexPath.row])
                self.dataSource.remove(at: indexPath.row)
                self.tableView.reloadData()
            }
            alert.addAction(remove)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "移除设备"
    }
    
    
}
