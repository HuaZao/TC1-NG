//
//  TCSocketWeekListViewController.swift
//  TC1-NG
//
//  Created by QAQ on 2019/5/8.
//  Copyright © 2019 TC1. All rights reserved.
//

import UIKit



class TCSocketWeekListViewController: UIViewController {
    
    struct Week{
        var title = String()
        var tag = 0
        var isSelector = false
    }
    
    
    @IBOutlet weak var tableView: UITableView!
    
    private var dateSource = [Week]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        for i in 1...8{
            let date = Week(title: self.intToString(number: i), tag: i,isSelector:false)
            self.dateSource.append(date)
        }
        
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
        case 8:
            string = "一次"
        default:
            break
        }
        return string
    }
    
    func transformWeekToBit(week:[Int])->String{
        var str = String()
//        var repetition = r_epeat
//        let week = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"]
//        repetition &= 0x7f
//        if repetition == 0{
//            str = "一次"
//            return str
//        }else if (repetition & 0x7f) == 0x7f{
//            str = "每天"
//            return str
//        }else{
//            for i in 0...6{
//                if (repetition & (1 << i)) != 0{
//                    str = str + "," + week[i]
//                }
//            }
//            str.removeFirst()
//        }
//        return str
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
        self.dateSource[indexPath.row].isSelector = !self.dateSource[indexPath.row].isSelector
        self.tableView.reloadRows(at: [indexPath], with: .automatic)
    }
    
    
}
