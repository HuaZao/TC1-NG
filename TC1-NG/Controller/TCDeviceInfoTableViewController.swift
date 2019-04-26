//
//  TCDeviceInfoTableViewController.swift
//  TC1-NG
//
//  Created by QAQ on 2019/4/25.
//  Copyright © 2019 TC1. All rights reserved.
//

import UIKit
import SwiftyJSON

class TCDeviceInfoTableViewController: UITableViewController {

    @IBOutlet weak var ipAddress: UILabel!
    @IBOutlet weak var macAddress: UILabel!
    @IBOutlet weak var mqttAddress: UILabel!
    @IBOutlet weak var version: UILabel!
    
    var deviceModel = TCDeviceModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.ipAddress.text = self.deviceModel.ip
        self.macAddress.text = self.deviceModel.mac
        self.mqttAddress.text = self.deviceModel.mqtt.host
        self.version.text = self.deviceModel.version
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? TCSetMQTTServiceViewController{
            vc.deviceModel = self.deviceModel
        }
    }

}
