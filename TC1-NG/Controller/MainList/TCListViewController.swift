//
//  TCListViewController.swift
//  TC1-NG
//
//  Created by QAQ on 2019/4/24.
//  Copyright © 2019 TC1. All rights reserved.
//

import UIKit
import SwiftyJSON

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
        self.dataSource = TCSQLManager.queryAllTCDevice() ?? [TCDeviceModel]()
        self.noDeviceBg.isHidden = !self.dataSource.isEmpty
        self.tableView.reloadData()
    }
    
    private func discoverDevices(mac:String){
        TC1MQTTManager.share.delegate = self
        TC1MQTTManager.share.initTC1Service(nil,mac: mac)
        TC1MQTTManager.share.sendDeviceReportCmd()
    }
    
    fileprivate func addTC(message:JSON){
        let model = TCDeviceModel()
        model.name = message["name"].stringValue
        model.mac = message["mac"].stringValue
        model.ip = message["ip"].stringValue
        model.sockets = [SocketModel]()
        //初始化6个插座
        for i in 1...6{
            let socket = SocketModel()
            socket.isOn = false
            socket.socketId = model.mac + "_\(i)"
            socket.sockeTtitle = "插座\(i)"
            model.sockets.append(socket)
        }
        TCSQLManager.addTCDevice(model)
        print("MAC:\(model.mac) 设备已经添加到本地")
        DispatchQueue.main.async {
            self.dataSource.append(model)
            self.noDeviceBg.isHidden = true
            self.tableView.reloadData()
        }
    }
    
}

extension TCListViewController:TC1MQTTManagerDelegate,NetServiceBrowserDelegate,NetServiceDelegate{
    
    func TC1MQTTManagerReceivedMessage(message: Data) {
        let messageJSON = try! JSON(data: message)
        //如果有IP信息,则添加设备!
        let ip = messageJSON["ip"].stringValue
        if ip.count > 0 && !TCSQLManager.deciveisExist(messageJSON["mac"].stringValue) {
            self.addTC(message: messageJSON)
        }
    }
    
    func TC1MQTTManagerPublish(messageId: Int) {
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
            if let ipData = sender.addresses{
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
            //判断是否TC1
            let jsonMessage = JSON(serviceDic)
            if jsonMessage["Protocol"].stringValue == "com.zyc.basic"{
                print("发现TC1设备!")
                self.discoverDevices(mac: jsonMessage["MAC"].stringValue)
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
        cell.deviceTitle.text = self.dataSource[indexPath.row].name
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let vc = UIStoryboard(name: "TCDeviceMain", bundle: nil).instantiateInitialViewController() as? TCDeviceMainViewController{
            vc.deviceModel = self.dataSource[indexPath.row]
            vc.title = self.dataSource[indexPath.row].name
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    
}
