//
//  TCSocketTaskViewController.swift
//  TC1-NG
//
//  Created by QAQ on 2019/4/30.
//  Copyright © 2019 TC1. All rights reserved.
//

import UIKit
import PKHUD

class TCSocketTaskViewController: UIViewController {
    
    @IBOutlet weak var pickTimer: UIDatePicker!
    @IBOutlet weak var onButton: UIButton!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var onSwitch: UISwitch!

    var task = TCTask()
    var taskIndex = 0
    var plug = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initTask()
    }
    
    
    private func initTask(){
        if task.action == 0 {
            self.onButton.isSelected  = false
            self.closeButton.isSelected = true
            self.onButton.backgroundColor =  #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
            self.closeButton.backgroundColor = #colorLiteral(red: 0.9872227311, green: 0.6766419411, blue: 0.1695483923, alpha: 1)
        }else{
            self.onButton.isSelected  = true
            self.closeButton.isSelected = false
            self.onButton.backgroundColor = #colorLiteral(red: 0.9872227311, green: 0.6766419411, blue: 0.1695483923, alpha: 1)
            self.closeButton.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        }
        self.onSwitch.isOn = (self.task.on == 1)
    }
    
    @IBAction func onAction(_ sender: UIButton) {
        self.onButton.isSelected  = true
        self.closeButton.isSelected = false
        self.onButton.backgroundColor = #colorLiteral(red: 0.9872227311, green: 0.6766419411, blue: 0.1695483923, alpha: 1)
        self.closeButton.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
    }
    
    @IBAction func closeAction(_ sender: UIButton) {
        self.onButton.isSelected  = false
        self.closeButton.isSelected = true
        self.onButton.backgroundColor =  #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        self.closeButton.backgroundColor = #colorLiteral(red: 0.9872227311, green: 0.6766419411, blue: 0.1695483923, alpha: 1)
    }
    
    @IBAction func saveAction(_ sender: UIButton) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        let times = dateFormatter.string(from: self.pickTimer.date).components(separatedBy: ":")
        if let hour = Int(times.first!),let minute = Int(times.last!){
            self.task.hour = hour
            self.task.minute = minute
        }
        self.task.on = self.onSwitch.isOn ? 1:0
        self.task.action = self.onButton.isSelected ? 1:0
        TC1MQTTManager.share.taskDevice(task: self.task, index: self.plug, taskIndex: self.taskIndex)
        self.navigationController?.popViewController(animated: true)
        HUD.flash(.labeledSuccess(title: "保存请求已经发送!", subtitle: nil), delay: 2)
    }
    
}
