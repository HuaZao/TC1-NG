<div align="center">
<img width="320" height="320" src="TC1_Logo.png" alt="TC1-NG"/>
</p>
</div>

## 概要

基于a2633063提供的固件,部分UI界面参照斐讯PhiHome的iOS客户端,取名PhiHome-NG,目前大部分功能已经完成,可供日常使用

## 自签教程
[自签教程](https://www.i4.cn/news_detail_31112.html)

## TC1
目前APP使用官方EasyLink_SDK,硬件配网成功但无任何回调
**解决办法:**   
1. 使用安卓APP配网 -> 打开本APP -> APP通过局域网自动识别出设备 -> 设置完成  
2. 使用本APP配网,进入配网页面 -> 输入WIFI密码 -> 点击配置 -> 观察TC1的指示灯,快闪然后常亮则配网成功,此时APP无任何反应 -> 直接退出配网页面 -> APP通过局域网自动识别出设备 -> 设置完成
3. 由于iOS系统限制,自签证书没添加对应的权限会识别不出WiFi名称,可以点击蓝色WiFi图标进行手动输入

## DC1
1. 没有设备,理论上能控制,不保证任何用户体验

## A1
1. 没有设备,理论上能控制,不保证任何用户体验
2. 定时任务还没加上去

## M1
1. 作者a2633063还没放出对应的固件

## TODO LIST

- [ ] 添加设备(不完善)
- [x] 自动发现局域网中的TC1
- [x] UDP通讯
- [x] MQTT通讯
- [x] 获取设备状态
- [x] 控制设备开关
- [x] 定时功能
- [x] 设置MQTT服务器
- [x] OTA更新
- [x] 多设备支持
- [x] 净化器A1支持
- [x] DC1支持
- [ ] M1支持


### 预览图
![](https://github.com/HuaZao/TC1-NG/blob/master/preview/index-nodevice.png)
![](https://github.com/HuaZao/TC1-NG/blob/master/preview/index.png)
![](https://github.com/HuaZao/TC1-NG/blob/master/preview/add-A1.png)
![](https://github.com/HuaZao/TC1-NG/blob/master/preview/add-TC1.png)
![](https://github.com/HuaZao/TC1-NG/blob/master/preview/tc1-main.png)
![](https://github.com/HuaZao/TC1-NG/blob/master/preview/device-info.png)
![](https://github.com/HuaZao/TC1-NG/blob/master/preview/device-a1.png)
![](https://github.com/HuaZao/TC1-NG/blob/master/preview/time-task.png)
![](https://github.com/HuaZao/TC1-NG/blob/master/preview/task-set.png)

