//
//  YMZBaseBLEDevice.h
//  BLESDK
//
//  Created by Y@o on 2017/12/6.
//  Copyright © 2017年 Y@o. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "YMZBLEDeviceProtocol.h"

#define BLEErrorDomain @"BLEErrorDomain"
/*！写数据回调 code 501:已经正在发送数据中 请等待 502:写数据超时超时  503：外设设备初始化未完成 504:命令查询超时无返回 505:没有建立连接*/
typedef void (^YMZWriteDataBlock)(BOOL success, NSError *_Nullable error);
/*! 请求（有返回值的命令）数据回调*/
typedef void (^YMZResponseBlock)(NSData *_Nullable response, NSError *_Nullable error);
@interface YMZBaseBLEDevice : NSObject<YMZBLEDeviceProtocol, CBPeripheralDelegate>

/**
 分包发送数据

 @param characteristic 指定的特征
 @param data 要发的数据
 @param writeDataBlock 写数据完成、失败回调  回调在非UI线程 需要刷新UI请切换UI线程
 */
- (void)subcontractWriteValueToCharacteristic:(CBCharacteristic *_Nonnull)characteristic value:(NSData *_Nonnull)data writeDataBlock:(YMZWriteDataBlock _Nullable)writeDataBlock;

/**
 发送带返回值的命令

 @param characteristic 指定的特征
 @param command 命令数据
 @param writeDataBlock 写命令完成、失败回调     回调在非UI线程 需要刷新UI请切换UI线程
 @param responseBlock 硬件响应信息            回调在非UI线程 需要刷新UI请切换UI线程
 */
- (void)writeCommandToCharacteristic:(CBCharacteristic *_Nonnull)characteristic command:(NSData *_Nonnull)command writeDataBlock:(YMZWriteDataBlock _Nullable)writeDataBlock responseBlock:(YMZResponseBlock _Nullable)responseBlock;
@end
