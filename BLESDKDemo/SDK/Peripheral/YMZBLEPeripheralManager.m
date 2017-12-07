//
//  YMZBLEPeripheralManager.m
//  BLESDKDemo
//
//  Created by Y@o on 2017/12/6.
//  Copyright © 2017年 Y@o. All rights reserved.
//

#import "YMZBLEPeripheralManager.h"
#import "YMZBaseServiceManager.h"

@interface YMZBLEPeripheralManager()<CBPeripheralManagerDelegate>

@property (nonatomic, strong) CBPeripheralManager *manager;

@property (nonatomic, strong) NSMutableArray<id<YMZServiceManagerProtocol>> *services;

@property (nonatomic, copy) void (^initCompletedBlock)(CBManagerState state);
@end

@implementation YMZBLEPeripheralManager

- (instancetype _Nonnull )initWithCompletedBlock:(void(^_Nonnull)(CBManagerState state))completedBlock {
    if (self = [super init]) {
        _manager = [[CBPeripheralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue()];
        self.initCompletedBlock = completedBlock;
    }
    return self;
}
- (NSMutableArray<id<YMZServiceManagerProtocol>> *)services {
    if (!_services) {
        _services = [NSMutableArray array];
    }
    return _services;
}
//开始广播
- (void)startAdvertising:(nullable NSDictionary<NSString *, id> *)advertisementData {
    [self.manager startAdvertising:advertisementData];
}
//停止广播
- (void)stopAdvertising {
    [self.manager stopAdvertising];
}
//设置连接延迟
- (void)setDesiredConnectionLatency:(CBPeripheralManagerConnectionLatency)latency forCentral:(CBCentral *)central {
    [self.manager setDesiredConnectionLatency:latency forCentral:central];
}
//添加服务
- (void)didAddServiceWithServiceManager:(_Nonnull id<YMZServiceManagerProtocol>)serviceManager {
    [self.services addObject:serviceManager];
    [self.manager addService:serviceManager.service];
}
- (void)removeWithServiceManager:(_Nonnull id<YMZServiceManagerProtocol>)serviceManager {
    if ([self.services containsObject:serviceManager]) {
        [self.services removeObject:serviceManager];
    }
    [self.manager removeService:serviceManager.service];
}
- (void)removeAllServices {
    [self.services removeAllObjects];
    [self.manager removeAllServices];
}

#pragma mark - 私有方法
- (id<YMZServiceManagerProtocol>)serviceByServiceUUIDSting:(NSString *)uuidString {
    return [self.services filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"service.UUID.UUIDString = %@",uuidString]].firstObject;
}
#pragma mark - CBPeripheralManagerDelegate
- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {
    if (peripheral.state == CBManagerStatePoweredOn) {
        //开启服务
        if (self.initCompletedBlock) {
            self.initCompletedBlock(peripheral.state);
        }
        
       NSArray<CBUUID *> *serviceUUIDs = [self.services valueForKeyPath:@"service.UUID"];
        
        [self startAdvertising:@{CBAdvertisementDataServiceUUIDsKey:serviceUUIDs,
                                 CBAdvertisementDataLocalNameKey:self.advertisementDataLocalName
                                 }];
    }
}
- (void)peripheralManager:(CBPeripheralManager *)peripheral willRestoreState:(NSDictionary<NSString *, id> *)dict {
    
}
- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(nullable NSError *)error {
    
}
- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(nullable NSError *)error {
    id<YMZServiceManagerProtocol> serviceManager = [self serviceByServiceUUIDSting:service.UUID.UUIDString];
    if (error) {
        [self.services removeObject:serviceManager];
    }else {
        //已添加服务serviceManager
    }
}
- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic {
    id<YMZServiceManagerProtocol> serviceManager = [self serviceByServiceUUIDSting:characteristic.service.UUID.UUIDString];
    if (serviceManager) {
        //central已订阅serviceManager服务的characteristic属性
        [serviceManager central:central didSubscribeToCharacteristic:characteristic];
    }
}
- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic {
    id<YMZServiceManagerProtocol> serviceManager = [self serviceByServiceUUIDSting:characteristic.service.UUID.UUIDString];
    if (serviceManager) {
        //central已取消订阅serviceManager服务的characteristic属性
        [serviceManager central:central didUnsubscribeFromCharacteristic:characteristic];
    }
}
- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request {
    
    CBCharacteristic *characteristic = request.characteristic;
    
    id<YMZServiceManagerProtocol> serviceManager = [self serviceByServiceUUIDSting:characteristic.service.UUID.UUIDString];
    if (serviceManager) {
        //已接收到central对serviceManager服务的characteristic特征的读请求
        [serviceManager didReceiveReadRequest:request];
    }
}
- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray<CBATTRequest *> *)requests {
    
    for (CBATTRequest *request in requests) {
        CBCharacteristic *characteristic = request.characteristic;
        id<YMZServiceManagerProtocol> serviceManager = [self serviceByServiceUUIDSting:characteristic.service.UUID.UUIDString];
        if (serviceManager) {
            //已接收到central对serviceManager服务的characteristic特征的写请求
            [serviceManager didReceiveWriteRequest:request];
        }
    }
}
- (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral {
    
}
- (void)peripheralManager:(CBPeripheralManager *)peripheral didPublishL2CAPChannel:(CBL2CAPPSM)PSM error:(nullable NSError *)error {
    
}
- (void)peripheralManager:(CBPeripheralManager *)peripheral didUnpublishL2CAPChannel:(CBL2CAPPSM)PSM error:(nullable NSError *)error {
    
}
- (void)peripheralManager:(CBPeripheralManager *)peripheral didOpenL2CAPChannel:(nullable CBL2CAPChannel *)channel error:(nullable NSError *)error {
    
}

@end
