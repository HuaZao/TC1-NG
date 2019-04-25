//
//  EASYLINK.h
//  EasyLink
//
//  Created by William Xu on 13-7-24.
//  Copyright (c) 2013年 MXCHIP. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SystemConfiguration/CaptiveNetwork.h>


@class ELAsyncUdpSocket;
@class ELAsyncSocket;
@class ELReachability;

typedef enum{
    EASYLINK_V1 = 0,
    EASYLINK_V2,
    EASYLINK_PLUS,
    EASYLINK_V2_PLUS,
    EASYLINK_AWS,
    EASYLINK_SOFT_AP,
    EASYLINK_MODE_MAX,
} EasyLinkMode;

typedef enum{
    eState_initialize,
    eState_connect_to_uap,
    eState_configured_by_uap,
    eState_connect_to_wrong_wlan,
    eState_connect_to_target_wlan,
} EasyLinkSoftApStage;

/*wlanConfig key */
#define KEY_SSID          @"SSID"               //value type: NSData, required
#define KEY_PASSWORD      @"PASSWORD"           //value type: NSString, required
#define KEY_DHCP          @"DHCP"               //value type: NSNumber(bool), required
#define KEY_IP            @"IP"                 //value type: NSString, required if DHCP is false
#define KEY_NETMASK       @"NETMASK"            //value type: NSString, required if DHCP is false
#define KEY_GATEWAY       @"GATEWAY"            //value type: NSString, required if DHCP is false
#define KEY_DNS1          @"DNS1"               //value type: NSString, required if DHCP is false
#define KEY_DNS2          @"DNS2"               //value type: NSString, required if DHCP is false

#define FTC_PORT 8000
#define AWS_ECHO_SERVER_PORT 65123
#define AWS_ECHO_CLIENT_PORT 65126
#define MessageCount 100

@protocol EasyLinkFTCDelegate
@required
/**
 @brief A new FTC client is found by FTC server in EasyLink
 @param client:         Client identifier.
 @param configDict:     Configuration data provided by FTC client
 @return none.
 */
- (void)onFoundByFTC:(NSNumber *)client withConfiguration: (NSDictionary *)configDict;

/**
 @brief A new FTC client is found by bonjour in EasyLink
 @note  Available only on MiCO version after 2.3.0
 @param client:         Client identifier.
 @param name:           Client name.
 @param mataDataDict:   Txt record provided by device
 @return none.
 */
- (void)onFound:(NSNumber *)client withName:(NSString *)name mataData: (NSDictionary *)mataDataDict;


/**
 @brief A FTC client is disconnected from FTC server in EasyLink
 @param client:         Client identifier.
 @param err:            Client is disconnected by error
 @return none.
 */
- (void)onDisconnectFromFTC:(NSNumber *)client  withError:(bool)err;

@optional
/**
 @brief EasyLink stage is changed during soft ap configuration mode
 @param stage:         The current stage.
 @return none.
 */
- (void)onEasyLinkSoftApStageChanged: (EasyLinkSoftApStage)stage;

- (void)onDisconnectFromFTC:(NSNumber *)client  __attribute__((deprecated));

@end

@interface EASYLINK : NSObject<NSNetServiceBrowserDelegate,
NSNetServiceDelegate>{
@private
    /* Wlan configuratuon send by EasyLink */
    NSObject *lockToken;
    NSUInteger _broadcastCount, _multicastCount, _awsCount;
    bool _broadcastSending, _multicastSending, _awsSending, _softAPSending, _wlanUnConfigured;
    
    NSString *_userInfo_str;
    
    EasyLinkMode _mode;
    
    NSMutableArray *multicastArray, *broadcastArray, *awsArray;   //Used for EasyLink transmitting
    NSArray *multicastGuideArray, *broadcastGuideArray, *awsGuideArray;   //Used for EasyLink transmitting
    ELAsyncUdpSocket *multicastSocket, *broadcastSocket, *awsSocket;
    
    //Used for EasyLink AWS new device discovery
    ELAsyncUdpSocket *awsEchoServer;
    NSMutableArray *awsHostsArrayPerSearch;
    
    //Used for EasyLink first time configuration
    ELAsyncSocket *ftcServerSocket;
    NSMutableArray *ftcClients;
    NSTimer *closeFTCClientTimer;
    
    NSNetServiceBrowser* _netServiceBrowser;
    NSMutableArray * _netServiceArray;
    NSDictionary * _configDict;
    
    CFHTTPMessageRef inComingMessageArray[MessageCount];
    ELReachability *wifiReachability;
    EasyLinkSoftApStage _softAPStage;
    uint32_t _identifier;
    
    id theDelegate;
}

@property (nonatomic, readonly) EasyLinkSoftApStage softAPStage;
@property (nonatomic, readonly) bool softAPSending;
@property (nonatomic, readonly) EasyLinkMode mode;

/* These delays should can only be write before prepareEasyLink_withFTC:info:mode is called. The less time is delayed, the faster Easylink may success,but wireless router would be under heavier pressure. So user should consider a balence between speed and wireless router's performance*/
@property (nonatomic, readwrite) float easyLinkPlusDelayPerByte;   //Default value: 0.005s
@property (nonatomic, readwrite) float easyLinkPlusDelayPerBlock;  //Default value: 0.06s, a block send 5 package
@property (nonatomic, readwrite) float easyLinkV2DelayPerBlock;    //Default value: 0.08s, a block send 1 package
@property (nonatomic, readwrite) float easyLinkAWSDelayPerByte;    //Default value: 0.02s

/* Enable debug log when EasyLink lib is running, disabled in default */
@property (nonatomic, readwrite) BOOL enableDebug;

- (id)initWithDelegate:(id)delegate;
- (id)initForDebug:(BOOL)enable WithDelegate:(id)delegate;

- (id)delegate;
- (void)setDelegate:(id)delegate;

/* 清除EasyLink实例时，请务必调用该API*/
- (void)unInit;

// Easylink sequence on all MiCO versions: (MiCO: firmware running on device that need to be configured)
// Application ---------------------------------EasyLink------------------------------------------MICO Device----------------------
// initWithDelegate:(id)delegate;     ->      Alloc EasyLink instance, create FTC server
// prepareEasyLink_withFTC:info:mode: ->      Store configurations
//
// EasyLink V2/Plus mode:==========================================================================================================
// transmitSettings                   ->      Send wlan configurations and IP->             Receive wlan configurations and FTC server's IP
//                                                                                          Connect to wlan
//                                            Accept FTC client              <-             Connect to FTC server
// onFoundByFTC:withConfiguration:    <-      Receive                        <-             Send current info and configuration
//
// stopTransmitting                   ->      Stop send wlan configurations
//
//
// EasyLink soft ap mode:==========================================================================================================
// transmitSettings                   ->      Start FTC monitoring
// onEasyLinkSoftApStageChanged:      <-      Connect to EasyLink_XXXXXX hotspot created by device in iOS settings by user
//                                            Find the new device, connect   ->             Accetp iOS connection
//                                            Send wlan configurations       ->             Receive wlan configurations
// onEasyLinkSoftApStageChanged:      <-      Receive                        <-             Send response
//                                                                                          Close Soft AP
//                                                                                          Connect to wlan
// iOS disconnect from Soft ap and connect to wlan (possiable manual operation required in iOS settings, because iOS may connect to
// another wlan rather than a previous connected wlan)
// onEasyLinkSoftApStageChanged:      <-      Connect to target wlan(same as MiCO device)
//                                            Find the new device, connect   ->             Accetp iOS connection
//                                            Read FTC configurations        ->             Receive
// onFoundByFTC:withConfiguration:    <-      Receive                        <-             Send FTC configurations
// stopTransmitting                   ->      Stop FTC monitoring
//
//
//================================================================================================================================
//
// At this step, the device has connect to the same wlan as iOS, If MiCO's version is below 2.3.0, wlan settings has not stored to
// flash storage. If App enter background while FTC client is connected, all FTC client will be disconnected, and leave them unconfigured
// You should excute the following function 1 to finish the EasyLink procedure. If MiCO's version is 2.3.0 or higher, the configuration
// can be finished here. But for compatibility purpose, you should always excute the function:1
//
//================================================================================================================================
// Now application has several choices:
//
// 1. Send first-time-configuration to device, and finish EasyLink procedure(necessary)
// configFTCClient:withConfiguration: ->      Send FTC configurations        ->             Receive FTC configurations
//                                                                                          Store all configurations
// onDisconnectFromFTC:               <-      Disconnect FTC client          <-             Disconnect from FTC server
//                                                                                          Reboot and enter normal running mode
//  unInit：                          ->      Clear EasyLink instance
//
// 2. Send OTA data to update device's firmware(option)
// otaFTCClient:withOTAData:          ->      Send OTA data                  ->             Receive OTA data
// onDisconnectFromFTC:               <-      Disconnect FTC client          <-             Disconnect from FTC server
//                                                                                          Reboot and apply new firmware
//                                            Accept FTC client              <-             Connect to FTC server
// onFoundByFTC:currentConfig:        <-      Receive                        <-             Send current info and configuration
//
// 3. Ignore FTC client and leave them unconfigured(option)
// closeFTCClient:                    ->      Disconnect FTC client          ->             Disconnect from FTC server，delete configurations, reboot
// onDisconnectFromFTC:               <-
//

// For devices running MiCO higher than 2.3.0
// Application ---------------------------------EasyLink-----------------------------------MICO Device----------------------
// initWithDelegate:(id)delegate;     ->      Alloc EasyLink instance, start FTC monitoring
// prepareEasyLink:info:mode:         ->      Store configurations
//
// =======================================EasyLink V2/Plus mode:===========================================================
// transmitSettings                   ->      Send wlan configurations       ->            Receive wlan configurations
//                                                                                         Connect to wlan, save configurations if success
// onFound:withName:mataData:         <-      Search MiCO device's IP address
// stopTransmitting                   ->      Stop send wlan configurations
//
//
// =======================================EasyLink soft ap mode:==============================================================
// transmitSettings                   ->      Start
// onEasyLinkSoftApStageChanged:      <-      Connect to EasyLink_XXXXXX hotspot created by device in iOS settings by user
//                                            Search MiCO device's IP address
//                                            Connect                        ->           Accept
//                                            Send wlan configurations       ->           Receive
// onEasyLinkSoftApStageChanged:      <-      Receive                        <-           Send response
//                                                                                        Close hotspot
//                                                                                        Connect to wlan, save configurations if success
// iOS disconnect from Soft ap and connect to wlan (possiable manual operation required in iOS settings, because iOS may connect to
// another wlan rather than a previous connected wlan, this condition can generate a call back: onEasyLinkSoftApStageChanged:eState_connect_to_wrong_wlan)
//
// onEasyLinkSoftApStageChanged:      <-      Connect to target wlan（same as MiCO device）
// onFound:withName:mataData:         <-      Search MiCO device's IP address
// stopTransmitting                   ->      stop
//
//
//================================================================================================================================
//
// At this step, no matter in EasyLink mode or Soft ap mode, MiCO device has connect to target wlan and save wlan configurations.
// The EasyLink procedure can be finished here, call unInit to dealloc the EasyLink instance. More, If local config service in enabled
// on MiCO devie, easylink can connect to this service automatically, and generate a callback to notify application, and you have
// several choice for more configurations.
//
//================================================================================================================================
//                                            Connect                         ->            Accept(If MiCO enable local configuration service)
//                                            Send request                    ->            Receive
// onFoundByFTC:withConfiguration:   <-       Receive                         <-            Send current info and configuration
//
// Now application has several choices:
//
// 1. Send first-time-configuration to device, and finish EasyLink procedure(option)
// configFTCClient:withConfiguration: ->      Send FTC configurations        ->             Receive FTC configurations
//                                                                                          Store all configurations
// onDisconnectFromFTC:               <-      Disconnect FTC client          <-             Disconnect from FTC server
//                                                                                          Reboot and enter normal running mode
//  unInit：                          ->      Clear EasyLink instance
//
// 2. Send OTA data to update device's firmware(option)
// otaFTCClient:withOTAData:          ->      Send OTA data                  ->             Receive OTA data
// onDisconnectFromFTC:               <-      Disconnect FTC client          <-             Disconnect from FTC server
//                                                                                          Reboot and apply new firmware
//                                            Accept FTC client              <-             Connect to FTC server
// onFoundByFTC:currentConfig:        <-      Receive                        <-             Send current info and configuration
//
// 3. Ignore FTC client and leave them unconfigured(option)
// closeFTCClient:                    ->      Disconnect FTC client          ->             Disconnect from FTC server，delete configurations, reboot
// onDisconnectFromFTC:               <-

//================================================================================================================================


// 针对所有MiCO版本设备的EasyLink流程
// iOS应用程序的API调用和需要处理的回调------------EasyLink 库------------------------------------------MICO 设备----------------------
// initWithDelegate:(id)delegate;     ->       初始化Easylink实例， 创建FTC服务器
// prepareEasyLink_withFTC:info:mode: ->      保存用户输入的无线网络参数
//
// =======================================EasyLink V2/Plus 模式下的流程:===========================================================
// transmitSettings                   ->      发送无线网络参数和本机IP地址        ->            接收无线网络参数和iOS设备的IP地址
//                                                                                          连接到无线网络（高于2.3.0版本的MiCO设备存储网络参数）
//                                            接收MiCO设备的连接请求             <-            连接iOS设备上的FTC服务器
// 回调onFoundByFTC:withConfiguration: <-      接收                            <-            发送MiCO设备的当前信息
//
// stopTransmitting                   ->      停止发送无线网络参数和本机IP地址
//
//
// =======================================EasyLink soft ap 模式下的流程:==============================================================
// transmitSettings                   ->      启动
// 回调onEasyLinkSoftApStageChanged:   <-      用户在iOS的系统才到连接到热点：EasyLink_XXXXXX
// （提示iOS设备已经连接上MiCO的热点）             通过Bonjour服务查找MiCO设备的地址  ->             接受iOS设备的连接请求
//                                            发送无线网络参数                  ->             接收无线网络参数
// onEasyLinkSoftApStageChanged:      <-      接收应答                         <-             发送应答
// （提示iOS设备已经将网络参数发送到MiCO）                                                        关闭热点
//                                                                                           连接到目标无线网络（高于2.3.0版本的MiCO设备存储网络参数）
// iOS 断开MiCO设备的热点，重新连接到目标无线网络，（由于iOS设备重新连接的网络和MiCO设备不是同一个网络，可能需要用户手动连接，如果网络连接错误，会产生回调
// onEasyLinkSoftApStageChanged:eState_connect_to_wrong_wlan）
// onEasyLinkSoftApStageChanged:      <-      连接上目标网络（与MiCO设备相同）
//  （提示iOS设备已经连接上目标网络）              通过Bonjour服务查找MiCO设备的地址
//                                            连接                            ->             接受iOS设备的连接请求
//                                            发送读取设备当前信息的请求          ->             接收
// （回调）onFoundByFTC:withConfiguration: <-   接收                            <-             发送MiCO设备的当前信息
// stopTransmitting                   ->      停止
//
//
//================================================================================================================================
//
// 到这步为止，不管是EasyLink模式还是Soft ap模式，MiCO设备都已经连接到了目标网络，如果MiCO版本低于2.3.0，拿无线网络设置还没有写入Flash。因此，如果APP
// 进入后台，会导致所有的MiCO设备断开连接，并且断开和网络的连接,恢复到原有设置。需要调用下面的方法1，将设置写入Flash，完成设置流程。如果MiCO版本高于2.3.0，
// 无线网络已经成功设置。以下步骤可以忽略。出于兼容考虑，一定要执行下面的方法1
//================================================================================================================================
// 现在:
//
// 1. 向MiCO设备发送配置参数，结束EasyLink配置流程（必须）
// configFTCClient:withConfiguration: ->      发送配置参数                     ->             接收配置参数
//                                                                                          存储所有配置参数，包括无线网络参数
// （回调）onDisconnectFromFTC:         <-     断开FTC客户端                   <-             断开iOS设备上的FTC服务器
//                                                                                          设备重启，正常运行（高于2.3.0版本的MiCO设备不需要重启）
//
//  unInit：                            ->    清除EasyLink实例
//
// 2. OTA升级（可选）
// otaFTCClient:withOTAData:           ->     发送OTA数据                     ->             接收OTA数据
// （回调）onDisconnectFromFTC:         <-     断开FTC客户端                   <-             断开iOS设备上的FTC服务器
//                                                                                          重新启动，更新固件
//                                            接收客户端连接                   <-             重新连接到iOS设备上的FTC服务器
// （回调）onFoundByFTC:currentConfig:  <-     接收                            <-             发送当前设备信息
//
// 3. 忽略设备（可选）
// closeFTCClient:                    ->      断开设备连接                     ->             断开与iOS服务器的连接，删除配置参数，重新启动
// （回调）onDisconnectFromFTC:        <-
//================================================================================================================================


// 针对高于MiCO版本2.3.0设备的EasyLink简化流程
// iOS应用程序的API调用和需要处理的回调------------EasyLink 库------------------------------------------MICO 设备----------------------
// initWithDelegate:(id)delegate;     ->      初始化Easylink实例，启动bonjour
// prepareEasyLink:info:mode:         ->      保存用户输入的无线网络参数
//
// =======================================EasyLink V2/Plus 模式下的流程:===========================================================
// transmitSettings                   ->      发送无线网络参数                  ->            接收无线网络参数和iOS设备的IP地址
//                                                                                         连接到无线网络,设备存储网络参数
// 回调onFound:withName:mataData:     <-      通过Bonjour服务查找MiCO设备的地址
// stopTransmitting                  ->      停止发送无线网络参数和本机IP地址
//
//
// =======================================EasyLink soft ap 模式下的流程:==============================================================
// transmitSettings                   ->      启动
// 回调onEasyLinkSoftApStageChanged:   <-      用户在iOS的系统才到连接到热点：EasyLink_XXXXXX
// （提示iOS设备已经连接上MiCO的热点）             通过Bonjour服务查找MiCO设备的地址，
//                                            连接                            ->             接受iOS设备的连接请求
//                                            发送无线网络参数                  ->             接收无线网络参数
// onEasyLinkSoftApStageChanged:      <-      接收应答                         <-             发送应答
// （提示iOS设备已经将网络参数发送到MiCO）                                                        关闭热点
//                                                                                           连接到目标无线网络（高于2.3.0版本的MiCO设备存储网络参数）
// iOS 断开MiCO设备的热点，重新连接到目标无线网络，（由于iOS设备重新连接的网络和MiCO设备不是同一个网络，可能需要用户手动连接，如果网络连接错误，会产生回调
// onEasyLinkSoftApStageChanged:eState_connect_to_wrong_wlan）
// onEasyLinkSoftApStageChanged:      <-      连接上目标网络（与MiCO设备相同）
//  （提示iOS设备已经连接上目标网络）
// 回调onFound:withName:mataData:     <-      通过Bonjour服务查找MiCO设备的地址
// stopTransmitting                  ->      停止
//
//
//================================================================================================================================
//
// 到这步为止，不管是EasyLink模式还是Soft ap模式，MiCO设备都已经连接到了目标网络，并且存储了网络参数,Easylink 配置流程可以到此结束, 使用unInit方法清除。
// EasyLink实例，除此之外，如果MiCO设备上启动了本地配置服务，EasyLink库会自动连接，产生回调，并且可以使用以下的功能。
//
//================================================================================================================================
//                                            连接                            ->             接受iOS设备的连接请求(如果MiCO设备开启本地配置服务)
//                                            发送读取设备当前信息的请求          ->             接收
// （回调）onFoundByFTC:withConfiguration: <-   接收                            <-             发送MiCO设备的当前信息
//
// 现在:
// 1. 向MiCO设备发送配置参数，结束EasyLink配置流程（可选）
// configFTCClient:withConfiguration: ->      发送配置参数                     ->             接收配置参数
//                                                                                          存储所有配置参数，包括无线网络参数
// （回调）onDisconnectFromFTC:         <-      断开FTC客户端                   <-             断开iOS设备上的FTC服务器
//                                                                                          设备重启，正常运行
//
// 2. OTA升级（可选）
// otaFTCClient:withOTAData:           ->     发送OTA数据                     ->             接收OTA数据
// （回调）onDisconnectFromFTC:         <-      断开FTC客户端                   <-             断开iOS设备上的FTC服务器
//                                                                                          重新启动，更新固件
//                                            接收客户端连接                   <-             重新连接到iOS设备上的FTC服务器
// （回调）onFoundByFTC:currentConfig:  <-     接收                            <-             发送当前设备信息
//
// 3. 忽略设备（可选）
// closeFTCClient:                    ->      断开设备连接                     ->             断开与iOS服务器的连接，删除配置参数，重新启动
// （回调）onDisconnectFromFTC:        <-
//
//
//  unInit：                            ->      清除EasyLink实例
//================================================================================================================================



/**
 @brief Transmit wlan configurations to MiCO device, and start to find new connected device
 using bonjour protocol. EasyLink will send a random number to MiCO device,
 that make MiCO devices have an unique idenfifier in every configuration procedure.
 So even config a same device, two configuration make it different. EasyLink generate
 callback - (void)onFound: withName: mataData: after find a new device. After that
 EasyLink will try to connect to MiCO device this http protocol, and fetch configurations
 on the MiCO device. If you enable local config server on the device, a callback will
 be generate: - (void)onFoundByFTC: withConfiguration:.
 
 通过EasyLink功能将无线网络参数发送到MiCO设备，同时EasyLink将启动bonjour协议查找新连接的MiCO设备。
 每一次调用都会产生一个随机码发送给MiCO设备，使得每一次配网成功的设备都有不同的编号，防止同一个设备在
 不同的配置过程中被发现。当发现新设备后，产生回调：- (void)onFound: withName: mataData:
 的同时EasyLink库会按HTTP协议尝试连接到新设备，如果MiCO设备上开启了本地配置服务，就会连接成功，产生回调：
 - (void)onFoundByFTC: withConfiguration:
 @note  Should be excuted before (void)transmitSettings.
 @note  Compatiable with all MiCO after 2.3.0. 设备运行的MiCO版本需要高于2.3.0
 @param wlanConfigDict: Wlan configurations, include SSID, password, address etc. refer to #define KEY_XXX
 @param userInfo:       Application defined specific data to be send by Easylink.
 @param easyLinkMode:   The mode of EasyLink.
 @param key:            Key to encrypt data transfered in Easylink.
 @return none.
 */
- (void)prepareEasyLink:(NSDictionary *)wlanConfigDict info:(NSData *)userInfo mode:(EasyLinkMode)easyLinkMode;
- (void)prepareEasyLink:(NSDictionary *)wlanConfigDict info:(NSData *)userInfo mode:(EasyLinkMode)easyLinkMode encrypt:(NSData *)key;


/**
 @brief This API contain all functions in - (void)prepareEasyLink:info:mode:, but it deliver
 iOS device's IP address rather than a random number. Device running MiCO lower than
 2.3.0 will connect to this address and send its configurations, EasyLink will generate
 - (void)onFoundByFTC: withConfiguration: directly without call
 - (void)onFound: withName: mataData:, because this new dvice is not found by bonjour.
 When config a MiCO device newer than 2.3.0, and config one device twice in less than
 1 miniute, Easylink wll generate wrong callback  - (void)onFound: withName: mataData:
 That is because EasyLink cannot find any difference on the same device in different
 configuration procedures.
 
 该API包含- (void)prepareEasyLink:info:mode: 中的所有功能，但是传输的不是随机编码而是iOS设备的地址，
 在低于2.3.0版本的MiCO中，设备会按照这个地址连接到iOS设备并且直接产生回调：- (void)onFoundByFTC: withConfiguration:
 而不产生通过bonjour协议产生的回调：- (void)onFound: withName: mataData:
 由于不传输随机数，EasyLink无法区分同一个设备在不同的配置下有任何不同，因此，使得在对版本高于2.3.0的MiCO
 设备进行配置时，如果对同一个设备两次配置的时间少于1分钟，会产生针对前一次配置的错误回调
 
 @note  Should be excuted before (void)transmitSettings.
 @note  Compatiable with all MiCO versions. 兼容所有MiCO版本
 @param wlanConfigDict: Wlan configurations, include SSID, password, address etc. refer to #define KEY_XXX
 @param userInfo:       Application defined specific data to be send by Easylink.
 @param easyLinkMode:   The mode of EasyLink.
 @param key:            Key to encrypt data transfered in Easylink.
 @return none.
 */
- (void)prepareEasyLink_withFTC:(NSDictionary *)wlanConfigDict info:(NSData *)userInfo mode: (EasyLinkMode)easyLinkMode;
- (void)prepareEasyLink_withFTC:(NSDictionary *)wlanConfigDict info:(NSData *)userInfo mode: (EasyLinkMode)easyLinkMode encrypt:(NSData *)key;


/**
 @brief Send wlan settings use the predefined EasyLink mode
 */
- (void)transmitSettings;

/**
 @brief Stop current Easylink delivery. It is suggested to stop EasyLink once a new device
 is found (Notified by onFoundByFTC:currentConfig: in protocol EasyLinkFTCDelegate).
 As the EasyLink V2/plus mode would reduce the performance of the wireless router.
 */
- (void)stopTransmitting;


/**
 @brief Send a dictionary that contains all of the first-time-configurations to the new deivice.
 Once the device has received, it will disconnect, and exit the EasyLionk configuration mode.
 This function initialize the device like cloud servive account, password, working configures
 etc. when user first connect the device to Internet.
 @note  This function can only be called a new device is called by
 - (void)onFoundByFTC:(NSNumber *) withConfiguration: (NSDictionary *)
 @param client:         Client identifier, read by onFoundByFTC:currentConfig: in protocol
 EasyLinkFTCDelegate.
 @param configDict:     Device configurations.
 @return none.
 */
- (void)configFTCClient:(NSNumber *)client withConfiguration: (NSDictionary *)configDict;

/**
 @brief Send new firmware to the new deivice. Once the device has received, it will disconnect,
 update to the new firmware, and reconnect to iOS.
 @note  This function can only be called a new device is called by
 - (void)onFoundByFTC:(NSNumber *) withConfiguration: (NSDictionary *)
 @param client:         Client identifier, read by onFoundByFTC:currentConfig: in protocol
 EasyLinkFTCDelegate.
 @param otaData:        New firmware data.
 @return none.
 */
- (void)otaFTCClient:(NSNumber *)client withOTAData: (NSData *)otaData;

/**
 @brief Disconnect the new device, and leave it unconfigured(device will not store wlan settings).
 @note  This function can only be called a new device is called by
 - (void)onFoundByFTC:(NSNumber *) withConfiguration: (NSDictionary *)
 @param client:         Client identifier, read by onFoundByFTC:currentConfig: in protocol
 EasyLinkFTCDelegate.
 @return none.
 */
- (void)closeFTCClient:(NSNumber *)client;


#pragma mark - Tools -

/**
 @brief Return the EasyLink library version.
 */
+ (NSString *)version;

/**
 @brief Return the WLan SSID string(UTF8 conding) connected by iOS currently.
 */
+ (NSString *)ssidForConnectedNetwork;

/**
 @brief Return the WLan SSID data (bytes) connected by iOS currently.
 */
+ (NSData *)ssidDataForConnectedNetwork;

/**
 @brief Return the WLan information connected by iOS currently.
 */
+ (NSDictionary *)infoForConnectedNetwork;

/**
 @brief Return the current iOS IP address on the wlan interface.
 */
+ (NSString *)getIPAddress;

/**
 @brief Return the current iOS netmask on the wlan interface.
 */
+ (NSString *)getNetMask;

/**
 @brief Return the current iOS broadcast address on the wlan interface.
 */
+ (NSString *)getBroadcastAddress;

/**
 @brief Return the current iOS gateway address on the wlan interface.
 */
+ (NSString *)getGatewayAddress;

@end
