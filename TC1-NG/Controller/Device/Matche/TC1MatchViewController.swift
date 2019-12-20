//
//  TC1MatchViewController.swift
//  TC1-NG
//
//  Created by cpu on 2019/8/13.
//  Copyright © 2019 TC1. All rights reserved.
//

import UIKit
import SafariServices

class TC1MatchViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func matchAction(_ sender: UIButton) {
           let confUrl = URL(string: "http://192.168.0.1")!
           let safarVc = SFSafariViewController(url: confUrl)
           self.present(safarVc, animated: true, completion: nil)
       }

    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        if let vc = segue.destination as? FXDeviceConfigViewController{
//            vc.deviceiType = .TC1
//        }
//    }

}
