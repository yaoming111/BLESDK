//
//  YMZBLEDeviceProtocol.h
//  BLESDK
//
//  Created by Y@o on 2017/12/6.
//  Copyright © 2017年 Y@o. All rights reserved.
//

#import <Foundation/Foundation.h>
@class CBPeripheral;
@class CBCentralManager;
@class CBCharacteristic;
@class CBService;

typedef void (^ConnectBlock)(BOOL success, NSString * _Nullable errorDescription);
/*! 断开回调*/
typedef void (^DisconnectBlock)(BOOL success, NSString * _Nullable errorDescription);

@protocol YMZBLEDeviceProtocol <NSObject>

NS_ASSUME_NONNULL_BEGIN
@required
@property (nonatomic, strong)   CBPeripheral *peripheral;
/*! 对中心设备的一个引用*/
@property (nonatomic, weak)     CBCentralManager *centralManager;
NS_ASSUME_NONNULL_END
/*! 异常断开重连 默认 NO  手动断开时请先赋值为NO防止断开后重新连接*/
@property (nonatomic, assign) BOOL reconnect;
@optional
/*! 发起连接*/
- (void)connectWithResultBlock:(ConnectBlock _Nullable )resultBlock;
/*! 断开连接*/
- (void)disConnectWithResultBlock:(DisconnectBlock _Nullable )resultBlock;
/*! 配置需要的特征 必须实现并正确配置*/
- (void)configCharacteristicsWithService:(CBService *_Nonnull)service;
/*! 连接成功*/
- (void)didConnected;
/*! 连接失败*/
- (void)didFailToConnect;
/*! 已断开*/
- (void)didDisConnected;
/*! 已接收到characteristic属性更新的数据*/
- (void)didUpdateValueForCharacteristic:(CBCharacteristic *_Nonnull)characteristic error:(NSError *_Nullable)error;

- (NSArray<CBUUID *> *_Nullable)servicesUUID;
@end
