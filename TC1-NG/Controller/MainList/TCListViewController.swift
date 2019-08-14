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
    fileprivate var serviceDataSource = [NetService]()
    private var dataSource = [TCDeviceModel]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.discoverDevices()
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
            if let vc = UIStoryboard(name: "TCDeviceMain", bundle: nil).instantiateViewController(withIdentifier: "TC1") as? TDDeviceMainViewController{
                vc.deviceModel = deviceModel
                vc.title = deviceModel.name
                self.navigationController?.pushViewController(vc, animated: true)
            }
        case .DC1:
            if let vc = UIStoryboard(name: "TCDeviceMain", bundle: nil).instantiateViewController(withIdentifier: "TC1") as? TDDeviceMainViewController{
                vc.deviceModel = deviceModel
                vc.title = deviceModel.name
                self.navigationController?.pushViewController(vc, animated: true)
            }
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
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let deviceModel = self.dataSource[sourceIndexPath.row]
        self.dataSource.remove(at: sourceIndexPath.row)
        self.dataSource.insert(deviceModel, at: destinationIndexPath.row)
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
