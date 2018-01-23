//
//  YMZPrinter.h
//  BLESDK
//
//  Created by Y@o on 2017/12/6.
//  Copyright © 2017年 Y@o. All rights reserved.
//

#import "YMZBaseBLEDevice.h"

@interface YMZPrinter : YMZBaseBLEDevice
/**
 分包发送数据
 
 @param data 要发的数据
 @param writeDataBlock 写数据完成、失败回调
 */
- (void)subcontractWriteValue:(NSData *_Nonnull)data writeDataBlock:(YMZWriteDataBlock _Nullable)writeDataBlock;

/**
 发送带返回值的命令
 
 @param command 命令数据
 @param writeDataBlock 写命令完成、失败回调
 @param responseBlock 硬件响应信息
 */
- (void)writeCommand:(NSData *_Nonnull)command writeDataBlock:(YMZWriteDataBlock _Nullable)writeDataBlock responseBlock:(YMZResponseBlock _Nullable)responseBlock;

/**
 读数据

 @param responseBlock 响应信息
 */
- (void)readDataWithResponseBlock:(YMZResponseBlock _Nullable )responseBlock;
@end
