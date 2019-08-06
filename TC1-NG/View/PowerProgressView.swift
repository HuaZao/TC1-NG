//
//  PowerProgressView.swift
//  TC1-NG
//
//  Created by QAQ on 2019/4/19.
//  Copyright © 2019 TC1. All rights reserved.
//

import UIKit

class PowerProgressView: UIView {
    
   private let MAXPower = 3000;
   private var gradientLayer:CAGradientLayer!
   private var shapeLayer:CAShapeLayer!
   private var powerLabel:UILabel!
   private var timer:Timer?
    
    
    override func awakeFromNib() {
        self.backgroundColor = UIColor.clear
        self.makePowerLabel()
    }
    
    public func setPoweDetailString(string:String){
        self.powerLabel.text = string
    }
    
    public func setCircleColor(color:UIColor){
        let circlePath = UIBezierPath(arcCenter: CGPoint(x: self.frame.size.width / 2, y: self.frame.size.height / 2), radius: (self.frame.size.width - 20)/2, startAngle: CGFloat.pi / 4 + CGFloat.pi / 2, endAngle: CGFloat.pi / 4, clockwise: true)
        let bgLayer = CAShapeLayer()
        bgLayer.frame = self.bounds
        bgLayer.fillColor = UIColor.clear.cgColor
        bgLayer.lineWidth = 20
        bgLayer.strokeColor = #colorLiteral(red: 0.831372549, green: 0.831372549, blue: 0.831372549, alpha: 1)
        bgLayer.strokeStart = 0
        bgLayer.strokeEnd = 1
        bgLayer.lineCap = CAShapeLayerLineCap.round
        bgLayer.path = circlePath.cgPath
        self.layer.addSublayer(bgLayer)
        
       self.shapeLayer = CAShapeLayer()
        self.shapeLayer.frame = self.bounds
        self.shapeLayer.fillColor = UIColor.clear.cgColor
        self.shapeLayer.lineWidth = 20
        self.shapeLayer.strokeColor = UIColor.blue.cgColor
        self.shapeLayer.strokeStart = 0
        self.shapeLayer.strokeEnd = 1
        self.shapeLayer.lineCap = CAShapeLayerLineCap.round
        self.shapeLayer.path = circlePath.cgPath
        self.layer.addSublayer(self.shapeLayer)
        
        self.gradientLayer = CAGradientLayer()
        
        let leftGradientLayer = CAGradientLayer()
        leftGradientLayer.frame = CGRect(x: 0, y: 0, width: self.frame.size.width / 2, height: self.frame.size.height)
        leftGradientLayer.colors = [#colorLiteral(red: 1, green: 1, blue: 0, alpha: 1).cgColor,#colorLiteral(red: 1, green: 0.5019607843, blue: 0, alpha: 1).cgColor]
        leftGradientLayer.locations = [0,0.9]
        leftGradientLayer.startPoint = CGPoint(x: 0, y: 1)
        leftGradientLayer.endPoint = CGPoint(x: 1, y: 0)
        self.gradientLayer.addSublayer(leftGradientLayer)
        let rightGradientLayer = CAGradientLayer()
        rightGradientLayer.frame = CGRect(x: self.frame.size.width / 2, y: 0, width: self.frame.size.width / 2, height: self.frame.size.height)
        rightGradientLayer.colors = [#colorLiteral(red: 1, green: 0.5019607843, blue: 0, alpha: 1).cgColor,#colorLiteral(red: 1, green: 0, blue: 0, alpha: 1).cgColor]
        rightGradientLayer.locations = [0.1,1]
        rightGradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        rightGradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        self.gradientLayer.addSublayer(rightGradientLayer)
        
        self.gradientLayer.mask = self.shapeLayer
        self.gradientLayer.frame = self.bounds
        self.layer.addSublayer(self.gradientLayer)
        
    }
    
    private func makePowerLabel(){
        let radius = self.frame.size.width / 2;
        self.powerLabel = UILabel(frame: CGRect(x: (self.frame.size.height - radius * 1.414) / 2, y: radius / 1.414 + radius - 10, width: radius * 1.414, height: 20))
        self.powerLabel.text = "插座功率"
        self.powerLabel.textAlignment = NSTextAlignment.center
        self.addSubview(self.powerLabel);
    }
    
//    跳转到某个进度
    public func animateToProgress(progress:Float){
        if self.shapeLayer.strokeEnd != 0{
            self.animateToZero()
        }
        let strokeDead = DispatchTimeInterval.seconds(Int(self.shapeLayer.strokeEnd))
        DispatchQueue.main.asyncAfter(deadline: .now() + strokeDead) {
            self.emptyTimer()
            self.timer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(self.progressAnimate(timer:)), userInfo: ["progress":CGFloat(progress)], repeats: true)
        }
        
        
    }
    
    @objc private func progressAnimate(timer:Timer){
        let progress = (timer.userInfo as! [String:CGFloat])["progress"]!
        if self.shapeLayer.strokeEnd <= progress{
            self.shapeLayer.strokeEnd = self.shapeLayer.strokeEnd + 0.01
        }else{
            self.emptyTimer()
        }
    }
    
    @objc private func progressAnimateReset(timer:Timer){
        if self.shapeLayer.strokeEnd > 0{
            self.shapeLayer.strokeEnd = self.shapeLayer.strokeEnd - 0.01
        }else{
            self.emptyTimer()
        }
    }
    
//    清空进度
    public func animateToZero(){
        self.emptyTimer()
        self.timer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(self.progressAnimateReset(timer:)), userInfo:nil, repeats: true)
        self.shapeLayer.strokeEnd  = 0
    }
    
    private func emptyTimer(){
        self.timer?.invalidate()
    }

}
