//
//  CHDBLEManagerProtocol.h
//  BLESDK
//
//  Created by Y@o on 2017/12/6.
//  Copyright © 2017年 Y@o. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CBCentralManager;
@class CBPeripheral;

@class YMZBLEManager;

@protocol YMZBLEDeviceProtocol;

@protocol YMZBLEManagerDelegate <NSObject>
@required
//central.state == CBManagerStatePoweredOn 才能发起搜索
- (void)BLEManager:(YMZBLEManager *)BLEManager centralManagerDidUpdateState:(CBCentralManager *)central;

- (void)BLEManager:(YMZBLEManager *)BLEManager didDiscoverDevice:(id<YMZBLEDeviceProtocol, CBPeripheralDelegate>)device;
@optional

@end

@protocol YMZBLEManagerDatasource <NSObject>
@required
/*! 在这里返回 遵守CHDDeviceProtocol,CBPeripheralDelegate 协议的外设对象*/
- (id<YMZBLEDeviceProtocol, CBPeripheralDelegate>)BLEManager:(YMZBLEManager *)BLEManager conversionCustomDeviceInstanceWithPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *, id> *)advertisementData RSSI:(NSNumber *)RSSI;

@optional

/*! 设备名称包含的字符数组 设备名称包含 数组指定的其中一个子串才能放进已搜索设备*/
- (NSArray<NSString *> *)deviceNameContainSubStringArray;
/*! 搜索服务的UUID数组*/
- (NSArray<CBUUID *> *)deviceServiceUUIDs:(id<YMZBLEDeviceProtocol>)device;

- (NSArray<CBUUID *> *)discoverCharacteristics:(CBService *)service;

/*! 有新的设备已连接*/
- (void)BLEManager:(YMZBLEManager *)BLEManager didConnictedDevice:(id<YMZBLEDeviceProtocol>)device;
@end

