//
//  YMZBaseBLEDevice.m
//  BLESDK
//
//  Created by Y@o on 2017/12/6.
//  Copyright © 2017年 Y@o. All rights reserved.
//

#import "YMZBaseBLEDevice.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "YMZGCDTimer.h"

@interface YMZBaseBLEDevice()
@property (nonatomic, copy) ConnectBlock    connectResultBlock;
@property (nonatomic, copy) DisconnectBlock disConnectResultBlock;

@end

@implementation YMZBaseBLEDevice{
    NSMutableDictionary *_writeDataDic;
    NSMutableDictionary *_responseDic;
    
    NSMutableArray<NSInvocation *> *_subcontractWriteValueInvocationQueue;
    NSMutableArray<NSInvocation *> *_writeValueInvocationQueue;
    NSMutableArray<NSInvocation *> *_writeCommandInvocationQueue;
    
    dispatch_source_t _writeDataTimer;
    dispatch_source_t _responseTimer;
}

@synthesize peripheral;
@synthesize centralManager;
@synthesize reconnect;

- (instancetype)init {
    if (self = [super init]) {
        _writeDataDic = [NSMutableDictionary dictionary];
        _responseDic = [NSMutableDictionary dictionary];
        _subcontractWriteValueInvocationQueue = [NSMutableArray array];
        _writeValueInvocationQueue = [NSMutableArray array];
        _writeCommandInvocationQueue = [NSMutableArray array];
    }
    return self;
}

#pragma mark - YMZBLEDeviceProtocol

#pragma mark - 主动调用
/*! 发起连接*/
- (void)connectWithResultBlock:(ConnectBlock)resultBlock {
    if (self.peripheral.state != CBPeripheralStateDisconnected) {
        if (resultBlock) {
            resultBlock(NO, [NSString stringWithFormat:@"当前设备状态是%ld 不是断开状态！！",self.peripheral.state]);
        }
        return;
    }
    self.connectResultBlock = resultBlock;
    [self.centralManager connectPeripheral:self.peripheral options:nil];
}
/*! 断开连接*/
- (void)disConnectWithResultBlock:(DisconnectBlock)resultBlock {
    if (self.peripheral.state == CBPeripheralStateDisconnected) {
        if (resultBlock) {
            resultBlock(NO, @"当前设备已是断开状态！！");
        }
        return;
    }
    self.disConnectResultBlock = resultBlock;
    [self.centralManager cancelPeripheralConnection:self.peripheral];
}

#pragma mark - 数据交互
- (void)subcontractWriteValueToCharacteristic:(CBCharacteristic *_Nonnull)characteristic value:(NSData *_Nonnull)data writeDataBlock:(YMZWriteDataBlock _Nullable)writeDataBlock {
    if (self.peripheral.state != CBPeripheralStateConnected) {
        NSError *error = [NSError errorWithDomain:BLEErrorDomain code:505 userInfo:@{ @"discription" : @"外设设备没有建立连接" }];
        
        if (writeDataBlock) {
            writeDataBlock(NO, error);
        }
        
        return;
    }
    
    if (!characteristic) {
        if (writeDataBlock) {
            NSError *error = [NSError errorWithDomain:BLEErrorDomain code:503 userInfo:nil];
            writeDataBlock(NO, error);
        }
        return;
    }
    
    NSMethodSignature *methodSignature = [self methodSignatureForSelector:@selector(invocationSubcontractWriteValueToCharacteristic:value:writeDataBlock:)];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
    [invocation setTarget:self];
    [invocation setSelector:@selector(invocationSubcontractWriteValueToCharacteristic:value:writeDataBlock:)];
    [invocation setArgument:&characteristic atIndex:2];
    [invocation setArgument:&data atIndex:3];
    [invocation setArgument:&writeDataBlock atIndex:4];
    [invocation retainArguments];
    
    dispatch_async(writerDataQueue(), ^{
        [_subcontractWriteValueInvocationQueue addObject:invocation];
        
        if (_subcontractWriteValueInvocationQueue.count == 1) {
            [invocation invoke];
        }
    });
}

- (void)invocationSubcontractWriteValueToCharacteristic:(CBCharacteristic *)characteristic value:(NSData *_Nonnull)data writeDataBlock:(YMZWriteDataBlock _Nullable)writeDataBlock {
    NSUInteger limitLength = 50;
    __block NSError *_Nullable aError = nil;
    NSUInteger dataLength = [data length];
    NSUInteger outCount = 0;
    NSUInteger sendCount = ceil((double_t)dataLength / limitLength);
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(1);
    
    for (NSUInteger i = 0; i < sendCount; i++) {
        if ((i + 1) * limitLength > dataLength) {
            outCount = (i + 1) * limitLength - dataLength;
        }
        NSData *d = [data subdataWithRange:NSMakeRange(i * limitLength, (limitLength - outCount))];
        [self writeValueToCharacteristic:characteristic value:d type:CBCharacteristicWriteWithResponse writeDataBlock:^(BOOL success, NSError * _Nullable error) {
            if (error) {
                aError = error;
            }
            dispatch_semaphore_signal(semaphore);
        }];
        
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    }
    
    if (writeDataBlock) {
        writeDataBlock(aError ? NO : YES, aError);
        if (_subcontractWriteValueInvocationQueue.count > 0) {
            [_subcontractWriteValueInvocationQueue removeObjectAtIndex:0];
        }
        if (_subcontractWriteValueInvocationQueue.count > 0) {
            NSInvocation *invocation = _subcontractWriteValueInvocationQueue.firstObject;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), writerDataQueue(), ^{
                [invocation invoke];
            });
        }
    }
}

- (void)writeCommandToCharacteristic:(CBCharacteristic *_Nonnull)characteristic command:(NSData *_Nonnull)command writeDataBlock:(YMZWriteDataBlock _Nullable)writeDataBlock responseBlock:(YMZResponseBlock _Nullable)responseBlock {
    if (self.peripheral.state != CBPeripheralStateConnected) {
        NSError *error = [NSError errorWithDomain:BLEErrorDomain code:505 userInfo:@{ @"discription" : @"外设设备没有建立连接" }];
        
        if (writeDataBlock) {
            writeDataBlock(NO, error);
        }
        
        if (responseBlock) {
            responseBlock(nil, error);
        }
        
        return;
    }
    
    if (!characteristic) {
        NSError *error = [NSError errorWithDomain:BLEErrorDomain code:503 userInfo:@{ @"discription" : @"外设设备初始化未完成" }];
        
        if (writeDataBlock) {
            writeDataBlock(NO, error);
        }
        
        if (responseBlock) {
            responseBlock(nil, error);
        }
        return;
    }
    NSMethodSignature *methodSignature = [self methodSignatureForSelector:@selector(invocationWriteCommandToCharacteristic:command:writeDataBlock:responseBlock:)];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
    [invocation setTarget:self];
    [invocation setSelector:@selector(invocationWriteCommandToCharacteristic:command:writeDataBlock:responseBlock:)];
    [invocation setArgument:&characteristic atIndex:2];
    [invocation setArgument:&command atIndex:3];
    [invocation setArgument:&writeDataBlock atIndex:4];
    [invocation setArgument:&responseBlock atIndex:5];
    [invocation retainArguments];
    
    [_writeCommandInvocationQueue addObject:invocation];
    if (_writeCommandInvocationQueue.count == 1) {
        [invocation invoke];
    }
}

- (void)invocationWriteCommandToCharacteristic:(CBCharacteristic *)characteristic command:(NSData *_Nonnull)command writeDataBlock:(YMZWriteDataBlock _Nullable)writeDataBlock responseBlock:(YMZResponseBlock _Nullable)responseBlock {
    YMZResponseBlock theResponseBlock = ^(NSData *response, NSError *error) {
        [_responseDic removeObjectForKey:characteristic.UUID.UUIDString];
        
        [YMZGCDTimer GCD_CancelTimer:_responseTimer];
        _responseTimer = nil;
        if (responseBlock) {
            if (_writeCommandInvocationQueue.count > 0) {
                [_writeCommandInvocationQueue removeObjectAtIndex:0];
            }
            
            if (_writeCommandInvocationQueue.count > 0) {
                NSInvocation *invocation = _writeCommandInvocationQueue.firstObject;
                [invocation invoke];
            }
            responseBlock(response, error);
        }
    };
    
    YMZWriteDataBlock theWriteDataBlock = ^(BOOL success, NSError *_Nullable error) {
        
        if (writeDataBlock) {
            writeDataBlock(success, error);
        }
        
        if (error) {
            if (theResponseBlock) {
                theResponseBlock(nil, error);
            }
        }
    };
    
    if ([_responseDic.allKeys containsObject:characteristic.UUID.UUIDString]) {
        NSError *error = [NSError errorWithDomain:BLEErrorDomain code:501 userInfo:@{ @"discription" : @"还有未回复的命令" }];
        
        if (theWriteDataBlock) {
            theWriteDataBlock(NO, error);
        }
        return;
    }
    if (theResponseBlock) {
        [_responseDic setObject:theResponseBlock forKey:characteristic.UUID.UUIDString];
    }
    
    _responseTimer = [YMZGCDTimer GCD_StartTimerWithTimeInterval:5 repeats:NO block:^{
        if (theResponseBlock) {
            NSError *error = [NSError errorWithDomain:BLEErrorDomain code:504 userInfo:@{ @"discription" : @"命令查询超时无返回" }];
            theResponseBlock(nil, error);
        }
    }];
    
    [self writeValueToCharacteristic:characteristic value:command type:CBCharacteristicWriteWithResponse writeDataBlock:^(BOOL success, NSError * _Nullable error) {
        if (theWriteDataBlock) {
            theWriteDataBlock(success, error);
        }
    }];
}

- (void)writeValueToCharacteristic:(CBCharacteristic *)characteristic value:(NSData *)data type:(CBCharacteristicWriteType)type writeDataBlock:(YMZWriteDataBlock)writeDataBlock {
    
    NSMethodSignature *methodSignature = [self methodSignatureForSelector:@selector(invocationWriteValueToCharacteristic:value:type:writeDataBlock:)];
    
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
    [invocation setTarget:self];
    [invocation setSelector:@selector(invocationWriteValueToCharacteristic:value:type:writeDataBlock:)];
    [invocation setArgument:&characteristic atIndex:2];
    [invocation setArgument:&data atIndex:3];
    [invocation setArgument:&type atIndex:4];
    [invocation setArgument:&writeDataBlock atIndex:5];
    [invocation retainArguments];
    
    [_subcontractWriteValueInvocationQueue addObject:invocation];
    if (_writeValueInvocationQueue.count == 1) {
        [invocation invoke];
    }
}

- (void)invocationWriteValueToCharacteristic:(CBCharacteristic *)characteristic value:(NSData *)data type:(CBCharacteristicWriteType)type writeDataBlock:(YMZWriteDataBlock)writeDataBlock {
    YMZWriteDataBlock theWriteDataBlock = ^(BOOL success, NSError *_Nullable error) {
        
        [YMZGCDTimer GCD_CancelTimer:_writeDataTimer];
        _writeDataTimer = nil;
        [_writeDataDic removeObjectForKey:characteristic.UUID.UUIDString];
        
        if (writeDataBlock) {
            writeDataBlock(success, error);
        }
        
        if (_writeValueInvocationQueue.count > 0) {
            [_writeValueInvocationQueue removeObjectAtIndex:0];
        }
        
        if (_writeValueInvocationQueue.count > 0) {
            NSInvocation *invocation = _writeValueInvocationQueue.firstObject;
            [invocation invoke];
        }
    };
    
    if ([_writeDataDic.allKeys containsObject:characteristic.UUID.UUIDString]) {
        NSError *error = [NSError errorWithDomain:BLEErrorDomain code:501 userInfo:@{ @"discription" : @"已经正在发送数据中" }];
        
        if (theWriteDataBlock) {
            theWriteDataBlock(NO, error);
        }
        return;
    }
    
    if (theWriteDataBlock) {
        [_writeDataDic setObject:theWriteDataBlock forKey:characteristic.UUID.UUIDString];
    }
    
    [self.peripheral writeValue:data forCharacteristic:characteristic type:type];
    
    _writeDataTimer = [YMZGCDTimer GCD_StartTimerWithTimeInterval:2 repeats:NO block:^{
        NSError *error = [NSError errorWithDomain:BLEErrorDomain code:502 userInfo:@{ @"discription" : @"写数据超时" }];
        theWriteDataBlock(NO, error);
    }];
    
}
#pragma mark - 私有方法
- (void)configCharacteristicsWithService:(CBService *_Nonnull)service {
    NSAssert(0, @"子类必须实现并正确配置");
}
#pragma mark - 被动调用
/*! 连接成功*/
- (void)didConnected {
    if (self.connectResultBlock) {
        self.connectResultBlock(YES, nil);
    }
}
/*! 连接失败*/
- (void)didFailToConnect {
    if (self.connectResultBlock) {
        self.connectResultBlock(NO, @"连接失败");
    }
}
/*! 已断开*/
- (void)didDisConnected {
    if (self.disConnectResultBlock) {
        self.disConnectResultBlock(YES, nil);
    }
}

#pragma mark - CBPeripheralDelegate
- (void)peripheralDidUpdateName:(CBPeripheral *)peripheral {
    
}
- (void)peripheral:(CBPeripheral *)peripheral didModifyServices:(NSArray<CBService *> *)invalidatedServices {
    
}
- (void)peripheralDidUpdateRSSI:(CBPeripheral *)peripheral error:(nullable NSError *)error {
    
}
- (void)peripheral:(CBPeripheral *)peripheral didReadRSSI:(NSNumber *)RSSI error:(nullable NSError *)error {
    
}
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(nullable NSError *)error {
    for (CBService *service in self.peripheral.services) {
        [self.peripheral discoverCharacteristics:nil forService:service];
    }
}
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverIncludedServicesForService:(CBService *)service error:(nullable NSError *)error {
    
}
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(nullable NSError *)error {
    [self configCharacteristicsWithService:service];
}
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error {
    
    YMZResponseBlock responseBlock = _responseDic[characteristic.UUID.UUIDString];
    
    if (responseBlock) {
        responseBlock(characteristic.value, error);
    }
    
    if ([self respondsToSelector:@selector(didUpdateValueForCharacteristic:error:)]) {
        [self didUpdateValueForCharacteristic:characteristic error:error];
    }
}
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error {
    YMZWriteDataBlock writeDataBlock = _writeDataDic[characteristic.UUID.UUIDString];
    if (writeDataBlock) {
        writeDataBlock(error ? NO : YES, error);
    }
}
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error {
    
}
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error {
    
}
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(nullable NSError *)error {
    
}
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForDescriptor:(CBDescriptor *)descriptor error:(nullable NSError *)error {

}
- (void)peripheralIsReadyToSendWriteWithoutResponse:(CBPeripheral *)peripheral {
    
}
- (void)peripheral:(CBPeripheral *)peripheral didOpenL2CAPChannel:(nullable CBL2CAPChannel *)channel error:(nullable NSError *)error {
    
}

    dispatch_queue_t writerDataQueue() {
    static dispatch_queue_t writerDataQueue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        writerDataQueue = dispatch_queue_create("com.xkeshi.printer.writerDataQueue", DISPATCH_QUEUE_SERIAL);
    });
    return writerDataQueue;
}

@end
