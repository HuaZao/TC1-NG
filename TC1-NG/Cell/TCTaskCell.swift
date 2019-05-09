//
//  TCTaskCell.swift
//  TC1-NG
//
//  Created by QAQ on 2019/4/30.
//  Copyright © 2019 TC1. All rights reserved.
//

import UIKit

class TCTaskCell: UITableViewCell {

    @IBOutlet weak var stateLabel: UILabel!
    @IBOutlet weak var stateSwitch: UISwitch!
    @IBOutlet weak var stateDetail: UILabel!
    @IBOutlet weak var timerDetail: UILabel!
    @IBOutlet weak var editButton: UIButton!
    
    private var task = TCTask()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    
    func message(task:TCTask,socketName:String,index:Int){
        self.task = task
        self.editButton.tag = index
        self.stateSwitch.tag = index
        if task.on == 1{
            self.stateSwitch.isOn = true
        }else{
            self.stateSwitch.isOn = false
        }
        if task.action == 1 {
            self.stateLabel.text = "开启\(socketName)"
        }else{
            self.stateLabel.text = "关闭\(socketName)"
        }
        self.timerDetail.text = String(format: "%02d:%02d", task.hour,task.minute)
        self.stateDetail.text = TCTask.getWeek(task.repeat)
        
    }

}
