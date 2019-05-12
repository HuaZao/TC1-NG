//
//  TCSocketWeekListViewController.swift
//  TC1-NG
//
//  Created by QAQ on 2019/5/8.
//  Copyright © 2019 TC1. All rights reserved.
//

import UIKit
import Bitter

class TCSocketWeekListViewController: UIViewController {
    
    struct Week{
        var title = String()
        var tag = 0
        var isSelector = false
    }
    
    
    @IBOutlet weak var timerSwitch: UISwitch!
    @IBOutlet weak var tableView: UITableView!
    
    private var dateSource = [Week]()
    
    /*bit0-bit6分别表示周一 ~ 周日
     值为85(二进制1010101->十进制0),表示星期一,星期三,星期五,星期天有效
     ........
     ........
     值为0(二进制0000000->十进制0),表示仅一次有效
     值为127(二进制1111111->十进制127),表示重复*/
    var week = 0
    var weekDetail = String()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initDataSource()
    }
    
    
    private func initDataSource(){
        self.week = 0
        self.weekDetail = "执行一次"
        self.dateSource.removeAll()
        if self.timerSwitch.isOn {
            for i in 1...7{
                let date = Week(title: self.intToString(number: i), tag: i,isSelector:false)
                self.dateSource.append(date)
            }
        }else{
            let date = Week(title: "执行一次", tag: 8,isSelector:true)
            self.dateSource.append(date)
        }
        self.tableView.reloadData()
    }
    
    
    func intToString(number: Int) -> String{
        var string = String()
        switch number {
        case 1:
            string = "星期一"
        case 2:
            string = "星期二"
        case 3:
            string = "星期三"
        case 4:
            string = "星期四"
        case 5:
            string = "星期五"
        case 6:
            string = "星期六"
        case 7:
            string = "星期日"
        default:
            break
        }
        return string
    }
    
    @IBAction func switchTimerAction(_ sender: UISwitch) {
        self.initDataSource()
    }
    
    //bit0~bit6
    private func transformWeekToBit(){
        var weekBit:UInt8 = 0b00000000
        var weekDescription = String()
        let selectorSource = self.dateSource.filter{$0.isSelector}
        for i in selectorSource {
            weekDescription = weekDescription + "," + i.title
            switch i.title {
            case "星期一":
                weekBit = weekBit.setb0(1)
            case "星期二":
                weekBit = weekBit.setb1(1)
            case "星期三":
                weekBit = weekBit.setb2(1)
            case "星期四":
                weekBit = weekBit.setb3(1)
            case "星期五":
                weekBit = weekBit.setb4(1)
            case "星期六":
                weekBit = weekBit.setb5(1)
            case "星期日":
                weekBit = weekBit.setb6(1)
            case "一次":
                weekBit = 0b00000000
            default:
                break
            }
        }
        self.weekDetail = weekDescription.replacingOccurrences(of: "星期", with: "周")
        self.weekDetail.removeFirst()
        self.week = Int(weekBit.to16)
    }
    
    
    @IBAction func affirmWeekAction(_ sender: UIBarButtonItem) {
        
    }
    
}

extension TCSocketWeekListViewController:UITableViewDelegate,UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dateSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier:"WeekCell", for: indexPath)  as! TCTimerCell
        cell.weekLabel.text = self.dateSource[indexPath.row].title
        cell.checkButton.isSelected = self.dateSource[indexPath.row].isSelector
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.timerSwitch.isOn == false {
            return
        }
        self.dateSource[indexPath.row].isSelector = !self.dateSource[indexPath.row].isSelector
        self.tableView.reloadRows(at: [indexPath], with: .automatic)
        self.transformWeekToBit()
    }
    
    
}
