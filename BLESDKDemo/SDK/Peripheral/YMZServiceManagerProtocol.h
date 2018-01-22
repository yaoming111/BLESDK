//
//  YMZServiceManagerProtocol.h
//  BLESDKDemo
//
//  Created by Y@o on 2017/12/6.
//  Copyright © 2017年 Y@o. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol YMZServiceManagerProtocol <NSObject>

@property (nonatomic, strong) CBMutableService *service;

//客户端订阅了该服务的characteristic指定特征
- (void)central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic;
//客户端取消订阅了该服务的characteristic指定特征
- (void)central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic;
//接收到读请求
- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request;
/*! 接收到写请求*/
- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequest:(CBATTRequest *)request;
@end
