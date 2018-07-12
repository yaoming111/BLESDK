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

typedef NS_OPTIONS(NSUInteger, YMZBleBaseRequestOptions) {
    YMZBleBaseRequestOptions_sendData = 1 << 0,
    YMZBleBaseRequestOptions_sendSubdata = 1 << 1,
};

@interface YMZBleBaseRequest:NSObject
/*! 请求对应的特征*/
@property (nonatomic, strong) CBCharacteristic *characteristic;
/*! 要发送的数据*/
@property (nonatomic, strong) NSData *data;
/*! 发送结束回调*/
@property (nonatomic, copy) YMZWriteDataBlock callback;
/*! 外设返回值回调*/
@property (nonatomic, copy) YMZResponseBlock responseBlock;
/*! 是否需要响应*/
@property (nonatomic, assign) CBCharacteristicWriteType type;

@property (nonatomic, assign) YMZBleBaseRequestOptions options;
@end

@implementation YMZBleBaseRequest

@end

@interface YMZBaseBLEDevice()
@property (nonatomic, copy) ConnectBlock    connectResultBlock;
@property (nonatomic, copy) DisconnectBlock disConnectResultBlock;
@end

@implementation YMZBaseBLEDevice{
    NSMutableDictionary *_writeDataDic;
    NSMutableDictionary *_responseDic;
    /*! 要分包发送的原始长数据*/
    NSMutableArray<YMZBleBaseRequest *> *_subcontractWriteValueInvocationQueue;
    /*! 已分包的数据段*/
    NSMutableArray<YMZBleBaseRequest *> *_writeValueInvocationQueue;
    /*! 要发送的命令数据*/
    NSMutableArray<YMZBleBaseRequest *> *_writeCommandInvocationQueue;
    
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
            if (self.peripheral.state == CBPeripheralStateConnected) {
                resultBlock(YES, @"设备已是连接状态，无需重复连接！！！");
            }else {
                resultBlock(NO, [NSString stringWithFormat:@"当前设备状态是%ld 不是断开状态！！！",self.peripheral.state]);
            }
        }
        return;
    }
    self.connectResultBlock = resultBlock;
    [self.centralManager connectPeripheral:self.peripheral options:nil];
}
/*! 断开连接*/
- (void)disConnectWithResultBlock:(DisconnectBlock)resultBlock {
    self.reconnect = NO;
    if (self.peripheral.state == CBPeripheralStateDisconnected) {
        if (resultBlock) {
            resultBlock(NO, @"当前设备已是断开状态！！！");
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
    
    YMZBleBaseRequest *request = [[YMZBleBaseRequest alloc] init];
    request.characteristic = characteristic;
    request.data = data;
    request.type = CBCharacteristicWriteWithoutResponse;
    request.callback = writeDataBlock;
    request.options = YMZBleBaseRequestOptions_sendData;
    
    [_subcontractWriteValueInvocationQueue addObject:request];
    if (_subcontractWriteValueInvocationQueue.count == 1) {
        dispatch_async(writerDataQueue(), ^{
             [self invocationSubcontractWriteValueToCharacteristic:request.characteristic value:request.data writeDataBlock:request.callback];
        });
    }
}

- (void)invocationSubcontractWriteValueToCharacteristic:(CBCharacteristic *)characteristic value:(NSData *_Nonnull)data writeDataBlock:(YMZWriteDataBlock _Nullable)writeDataBlock {
    NSUInteger limitLength = 50;
    __block NSError *_Nullable aError = nil;
    NSUInteger dataLength = [data length];
    NSUInteger outCount = 0;
    NSUInteger sendCount = ceil((double_t)dataLength / limitLength);
   
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
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
            YMZBleBaseRequest *request = _subcontractWriteValueInvocationQueue.firstObject;
            [self invocationSubcontractWriteValueToCharacteristic:request.characteristic value:request.data writeDataBlock:request.callback];
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
    
    YMZBleBaseRequest *request = [[YMZBleBaseRequest alloc] init];
    request.characteristic = characteristic;
    request.data = command;
    request.type = CBCharacteristicWriteWithResponse;
    request.callback = writeDataBlock;
    request.responseBlock = responseBlock;
    [_writeCommandInvocationQueue addObject:request];
    if (_writeCommandInvocationQueue.count == 1) {
        [self invocationWriteCommandToCharacteristic:request.characteristic command:request.data writeDataBlock:request.callback responseBlock:request.responseBlock];
    }
}

- (void)invocationWriteCommandToCharacteristic:(CBCharacteristic *)characteristic command:(NSData *_Nonnull)command writeDataBlock:(YMZWriteDataBlock _Nullable)writeDataBlock responseBlock:(YMZResponseBlock _Nullable)responseBlock {
    YMZResponseBlock theResponseBlock = ^(NSData *response, NSError *error) {
        [YMZGCDTimer GCD_CancelTimer:_responseTimer];
        _responseTimer = nil;
        if (responseBlock) {
            if (_writeCommandInvocationQueue.count > 0) {
                [_writeCommandInvocationQueue removeObjectAtIndex:0];
            }
            
            if (_writeCommandInvocationQueue.count > 0) {
                YMZBleBaseRequest *request = _writeCommandInvocationQueue.firstObject;
                [self invocationWriteCommandToCharacteristic:request.characteristic command:request.data writeDataBlock:request.callback responseBlock:request.responseBlock];
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
        _responseDic[characteristic.UUID.UUIDString] = theResponseBlock;
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
    
    YMZBleBaseRequest *request = [[YMZBleBaseRequest alloc] init];
    request.characteristic = characteristic;
    request.data = data;
    request.type = type;
    request.callback = writeDataBlock;
    request.options = YMZBleBaseRequestOptions_sendSubdata;
    
    [_writeValueInvocationQueue addObject:request];
    if (_writeValueInvocationQueue.count == 1) {
        [self invocationWriteValueToCharacteristic:request.characteristic value:request.data type:type writeDataBlock:request.callback];
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
            YMZBleBaseRequest *request = _writeValueInvocationQueue.firstObject;
            [self invocationWriteValueToCharacteristic:request.characteristic value:request.data type:request.type writeDataBlock:request.callback];
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
#pragma mark - 读指定特征内容
- (void)readValueForCharacteristic:(CBCharacteristic *)characteristic responseBlock:(YMZResponseBlock)responseBlock {
    if (self.peripheral.state != CBPeripheralStateConnected) {
        NSError *error = [NSError errorWithDomain:BLEErrorDomain code:505 userInfo:@{ @"discription" : @"外设设备没有建立连接" }];
        if (responseBlock) {
            responseBlock(nil, error);
        }
        
        return;
    }
    
    if (!characteristic) {
        NSError *error = [NSError errorWithDomain:BLEErrorDomain code:503 userInfo:@{ @"discription" : @"外设设备初始化未完成" }];
        if (responseBlock) {
            responseBlock(nil, error);
        }
        return;
    }
    
    if(!characteristic) {
        if (responseBlock) {
            NSError *error = [NSError errorWithDomain:BLEErrorDomain code:510 userInfo:@{ @"discription" : @"指定特征为空"}];
            responseBlock(nil, error);
        }
        return;
    }
    _responseDic[characteristic.UUID.UUIDString] = responseBlock;
    [self.peripheral readValueForCharacteristic:characteristic];
}

#pragma mark - 私有方法
- (void)configCharacteristicsWithService:(CBService *_Nonnull)service {
    NSAssert(0, @"子类必须实现并正确配置");
}
#pragma mark - 被动调用
/*! 连接成功*/
- (void)didConnected {
    [self.peripheral discoverServices:[self servicesUUID]];
    if (self.connectResultBlock) {
        self.connectResultBlock(YES, nil);
        self.connectResultBlock = nil;
    }
}
/*! 连接失败*/
- (void)didFailToConnect {
    if (self.connectResultBlock) {
        self.connectResultBlock(NO, @"连接失败");
        self.connectResultBlock = nil;
    }
}
/*! 已断开*/
- (void)didDisConnected {
    if (self.disConnectResultBlock) {
        self.disConnectResultBlock(YES, nil);
        self.disConnectResultBlock = nil;
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
        _responseDic[characteristic.UUID.UUIDString] = nil;
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

dispatch_queue_t writerDataQueue() {
    static dispatch_queue_t writerDataQueue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        writerDataQueue = dispatch_queue_create("com.ymz.writerDataQueue", DISPATCH_QUEUE_SERIAL);
    });
    return writerDataQueue;
}

@end
