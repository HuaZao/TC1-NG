//
//  TCSocketViewController.swift
//  TC1-NG
//
//  Created by QAQ on 2019/4/29.
//  Copyright © 2019 TC1. All rights reserved.
//

import UIKit
import SwiftyJSON

struct TCTask {
    var id = 0
    var `repeat` = 0
    var action = 0
    var minute = 0
    var hour = 0
    var on = 0
    
    static func getWeek(_ r_epeat:Int)->String{
        var str = String()
        var repetition = r_epeat
        let week = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"]
        repetition &= 0x7f
        if repetition == 0{
            str = "一次"
            return str
        }else if (repetition & 0x7f) == 0x7f{
            str = "每天"
            return str
        }else{
            for i in 0...6{
                if (repetition & (1 << i)) != 0{
                    str = str + "," + week[i]
                }
            }
            str.removeFirst()
        }
        return str
    }
}

class TCSocketViewController: UIViewController {
    
    @IBOutlet weak var noTimerView: UIImageView!
    @IBOutlet weak var tableView: UITableView!
    
    var plug = 0
    var taskDataSource = [TCTask]()
    override func viewDidLoad() {
        super.viewDidLoad()
        TC1MQTTManager.share.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        TC1MQTTManager.share.queryTask(index: plug)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let vc = segue.destination as? TCSocketTaskViewController,let sender = sender as? UIButton{
            vc.task = self.taskDataSource[sender.tag]
            print("第\(sender.tag)组定时器")
            vc.plug = self.plug
            vc.taskIndex = sender.tag
        }
        
    }
    
    fileprivate func reloadTaskList(messag:JSON){
         let task = messag["plug_\(plug)"]["setting"].dictionaryValue
           //五组定时
        for i in 0...4{
            if let row = task["task_\(i)"]?.dictionaryValue{
                let taskRow = TCTask(id:i,repeat:row["repeat"]?.intValue ?? 0, action: row["action"]?.intValue ?? 0, minute: row["minute"]?.intValue ?? 0, hour: row["hour"]?.intValue ?? 0, on: row["on"]?.intValue ?? 0)
                if self.taskDataSource.count != 0 && self.taskDataSource.contains{$0.id == i}{
                    if let index = self.taskDataSource.lastIndex(where: {$0.id == i}){
                        print("更新Model -> task_\(i)")
                        self.taskDataSource[index] = taskRow
                    }
                }else{
                    self.taskDataSource.append(taskRow)
                }
            }
        }
        self.noTimerView.isHidden = (self.taskDataSource.count != 0)
        self.tableView.reloadData()
    }
    
    @IBAction func switchTaskAction(_ sender: UISwitch) {
        var task = self.taskDataSource[sender.tag]
        task.on = sender.isOn ? 1:0
        TC1MQTTManager.share.taskDevice(task: task, index: self.plug, taskIndex: sender.tag)
    }
    
}

extension TCSocketViewController:TC1MQTTManagerDelegate,UITableViewDelegate,UITableViewDataSource{
    
    func TC1MQTTManagerReceivedMessage(message: Data) {
        let messageJSON = try! JSON(data: message)
        let power = messageJSON["power"].floatValue
        //过滤Power信息
        if power > 0 {
            return
        }
        self.reloadTaskList(messag: messageJSON)
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.taskDataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "task", for: indexPath) as! TCTaskCell
        cell.message(task: self.taskDataSource[indexPath.row], index: indexPath.row)
        return cell
    }
    
}
