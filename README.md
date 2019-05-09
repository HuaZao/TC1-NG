<div align="center">
<img width="320" height="320" src="TC1_Logo.png" alt="TC1-NG"/>
</p>
</div>

## Summary

基于a2633063提供的固件,部分UI界面参照斐讯PhiHome的iOS客户端,取名PhiHome-NG,目前大部分功能已经完成,可供日常使用

## 关于TC1配网

目前APP使用官方EasyLink_SDK,硬件配网成功但无任何回调,暂时无解.
解决办法:
1.使用安卓APP配网 -> 打开本APP -> APP通过局域网自动识别出设备 -> 设置完成
2.使用本APP配网,进入配网页面 -> 输入WIFI密码 -> 点击配置 -> 观察TC1的指示灯,快闪然后常亮则配网成功,此时APP无任何反应 -> 直接退出配网页面 -> APP通过局域网自动识别出设备 -> 设置完成


## TODO LIST

- [ ] 添加设备(不完善)
- [x] 自动发现局域网中的TC1
- [x] UDP通讯
- [ ] MQTT通讯(还没写好UDP和MQTT自动切换的逻辑,目前默认UDP)
- [x] 获取设备状态
- [x] 控制设备开关
- [x] 定时功能
- [x] 设置MQTT服务器
- [x] OTA更新
- [x] 多设备支持

### 预览图
![](https://github.com/HuaZao/TC1-NG/blob/master/ScreenShot1.png)
![](https://github.com/HuaZao/TC1-NG/blob/master/ScreenShot8.png)
![](https://github.com/HuaZao/TC1-NG/blob/master/ScreenShot2.png)
![](https://github.com/HuaZao/TC1-NG/blob/master/ScreenShot3.png)
![](https://github.com/HuaZao/TC1-NG/blob/master/ScreenShot4.png)
![](https://github.com/HuaZao/TC1-NG/blob/master/ScreenShot5.png)
![](https://github.com/HuaZao/TC1-NG/blob/master/ScreenShot6.png)
