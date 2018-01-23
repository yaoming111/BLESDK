//
//  YMZBLEPeripheralManager.h
//  BLESDKDemo
//
//  Created by Y@o on 2017/12/6.
//  Copyright © 2017年 Y@o. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "YMZServiceManagerProtocol.h"

@interface YMZBLEPeripheralManager : NSObject

@property(nonatomic, copy) NSString * _Nullable advertisementDataLocalName;

/*! 初始化方法请在completedBlock state == CBManagerStatePoweredOn时添加服务*/
- (instancetype _Nonnull )initWithCompletedBlock:(void(^_Nonnull)(CBManagerState state))completedBlock;
//开始广播
- (void)startAdvertising:(nullable NSDictionary<NSString *, id> *)advertisementData;
//停止广播
- (void)stopAdvertising;
//设置连接延迟
- (void)setDesiredConnectionLatency:(CBPeripheralManagerConnectionLatency)latency forCentral:(CBCentral *_Nonnull)central;
//添加服务
- (void)didAddServiceWithServiceManager:(_Nonnull id<YMZServiceManagerProtocol>)serviceManager;

- (void)removeWithServiceManager:(_Nonnull id<YMZServiceManagerProtocol>)serviceManager;

- (void)removeAllServices;
@end
