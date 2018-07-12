//
//  YMZBLEManager.h
//  BLESDK
//
//  Created by Y@o on 2017/12/6.
//  Copyright © 2017年 Y@o. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "YMZBLEDeviceProtocol.h"
#import "YMZBLEManagerProtocol.h"
@interface YMZBLEManager : NSObject

NS_ASSUME_NONNULL_BEGIN
/*! 已搜索到的设备*/
@property (nonatomic, strong, readonly) NSMutableArray<id<YMZBLEDeviceProtocol>> *didDiscoverPeripherals;
/*! 已连接的设备*/
@property (nonatomic, strong, readonly) NSMutableArray<id<YMZBLEDeviceProtocol>> *didConnectedPeripherals;

- (instancetype)initWithDelegate:(id<YMZBLEManagerDelegate>)delegate datasource:(id<YMZBLEManagerDatasource>)datasource;
/*! 设备当前状态 eg: CBManagerStatePoweredOff 设备未开启蓝牙开关 */
- (CBManagerState)deviceState;
/*! 指定服务搜索*/
- (void)scanForPeripheralsWithServiceUUIDStrings:(nullable NSArray<NSString *> *)serviceUUIDStrings;
/*! 停止搜索*/
- (void)stopScan;
NS_ASSUME_NONNULL_END
@end
