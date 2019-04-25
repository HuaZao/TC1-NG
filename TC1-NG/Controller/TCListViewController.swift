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
    
    private var dataSource = [TCDeviceModel]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.dataSource = TCSQLManager.queryAllTCDevice() ?? [TCDeviceModel]()
        self.noDeviceBg.isHidden = !self.dataSource.isEmpty
        self.tableView.reloadData()
    }
    
//    自动发现未添加的设备(暂不支持,需要先知道设备MAC,才能发现设备)
    private func discoverDevices(){
        TC1MQTTManager.share.delegate = self
        TC1MQTTManager.share.sendDeviceReportCmd()
    }

}

extension TCListViewController:TC1MQTTManagerDelegate{
    
    func TC1MQTTManagerReceivedMessage(message: Data) {
        let messageJSON = try! JSON(data: message)
        print(messageJSON)
    }
    
    func TC1MQTTManagerPublish(messageId: Int) {
        print("消息已经发送--> \(messageId)")
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
