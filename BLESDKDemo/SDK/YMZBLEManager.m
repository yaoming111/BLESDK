//
//  YMZBLEManager.m
//  BLESDK
//
//  Created by Y@o on 2017/12/6.
//  Copyright © 2017年 Y@o. All rights reserved.
//

#import "YMZBLEManager.h"

@interface YMZBLEManager()<CBCentralManagerDelegate>

@property (nonatomic, weak) id<CHDBLEManagerDelegate> delegate;

@property (nonatomic, weak) id<CHDBLEManagerDatasource> datasource;

@property (nonatomic, strong) CBCentralManager *centralManager;
//一搜索到的设备
@property (nonatomic, strong, readwrite) NSMutableArray<id<YMZBLEDeviceProtocol>> *didDiscoverPeripherals;
//已连接的设备
@property (nonatomic, strong, readwrite) NSMutableArray<id<YMZBLEDeviceProtocol>> *didConnectedPeripherals;
@end

@implementation YMZBLEManager

- (instancetype)initWithDelegate:(id<CHDBLEManagerDelegate>)delegate datasource:(id<CHDBLEManagerDatasource>)datasource {
    if (self = [super init]) {
        _delegate = delegate;
        _datasource = datasource;
        _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:centralManagerDelegateQueue()];
    }
    return self;
}

- (CBManagerState)deviceState {
    
    return self.centralManager.state;
}

- (void)scanForPeripheralsWithServiceUUIDStrings:(nullable NSArray<NSString *> *)serviceUUIDStrings {
    
    if (self.centralManager.isScanning) {
        [self.centralManager stopScan];//暂停搜索
    }
    NSArray *tempArr = [NSArray arrayWithArray:self.didDiscoverPeripherals];
    for (id<YMZBLEDeviceProtocol> device in tempArr) {//移除非连接状态的外设
        if (device.peripheral.state != CBPeripheralStateConnected) {
            [self.centralManager cancelPeripheralConnection:device.peripheral];
            [self.didDiscoverPeripherals removeObject:device];
        }
    }
    
    NSMutableArray<CBUUID *> * serviceUUIDs = [NSMutableArray array];
    for (NSString *serviceUUIDString in serviceUUIDStrings) {
        CBUUID *cbuuid = [CBUUID UUIDWithString:serviceUUIDString];
        [serviceUUIDs addObject:cbuuid];
    }
    [self.centralManager scanForPeripheralsWithServices:serviceUUIDs options:nil];
}

- (void)stopScan {
    [self.centralManager stopScan];
}

#pragma mark - 私有方法

- (NSMutableArray<id<YMZBLEDeviceProtocol>> *)didDiscoverPeripherals {
    if (!_didDiscoverPeripherals) {
        _didDiscoverPeripherals = [NSMutableArray array];
    }
    return _didDiscoverPeripherals;
}

- (NSMutableArray<id<YMZBLEDeviceProtocol>> *)didConnectedPeripherals {
    if (!_didConnectedPeripherals) {
        _didConnectedPeripherals = [NSMutableArray array];
    }
    return _didConnectedPeripherals;
}

- (void)addDidDiscoverDevice:(id<YMZBLEDeviceProtocol, CBPeripheralDelegate>)device {
    if (![[self.didDiscoverPeripherals valueForKeyPath:@"peripheral.identifier"] containsObject:device.peripheral.identifier]) {
        device.centralManager = self.centralManager;
        device.peripheral.delegate = device;
        [self.didDiscoverPeripherals addObject:device];
        if ([self.delegate respondsToSelector:@selector(BLEManager:didDiscoverDevice:)]) {
            [self.delegate BLEManager:self didDiscoverDevice:device];
        }
    }
}

- (void)addDidConnictedDevice:(id<YMZBLEDeviceProtocol>)device {
    
    if (![[self.didConnectedPeripherals valueForKeyPath:@"peripheral.identifier"] containsObject:device.peripheral.identifier]) {//防重复添加
        [self.didConnectedPeripherals addObject:device];
        if ([self.datasource respondsToSelector:@selector(BLEManager:didConnictedDevice:)]) {
            [self.datasource BLEManager:self didConnictedDevice:device];
        }
        [device didConnected];
    }
}

- (void)removeDidConnictedDevice:(id<YMZBLEDeviceProtocol>)device {
   
    if ([self.didConnectedPeripherals containsObject:device]) {
        [self.didConnectedPeripherals removeObject:device];
    }
}
- (id<YMZBLEDeviceProtocol>)bleDeviceByIdentifier:(NSString *)identifier {
    id<YMZBLEDeviceProtocol> device = [[self.didDiscoverPeripherals filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"peripheral.identifier.UUIDString = %@", identifier]] firstObject];
    
    return device;
}
#pragma mark - CBCentralManagerDelegate
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    if ([self.delegate respondsToSelector:@selector(BLEManager:centralManagerDidUpdateState:)]) {
        [self.delegate BLEManager:self centralManagerDidUpdateState:central];
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *, id> *)advertisementData RSSI:(NSNumber *)RSSI {
    
    NSArray *deviceNameContainSubStringArray = nil;
    if ([self.datasource respondsToSelector:@selector(deviceNameContainSubStringArray)]) {
        deviceNameContainSubStringArray = [self.datasource deviceNameContainSubStringArray];
    }
    
    if ([deviceNameContainSubStringArray isKindOfClass:[NSArray class]] && deviceNameContainSubStringArray.count > 0) {
        BOOL containsString = NO;
        for (NSString *subName in deviceNameContainSubStringArray) {
            containsString = [peripheral.name containsString:subName];
            if (containsString) {
                break;
            }
        }
        
        if (!containsString) {
            return;
        }
    }
    
    id<YMZBLEDeviceProtocol, CBPeripheralDelegate> device = [self.datasource BLEManager:self conversionCustomDeviceInstanceWithPeripheral:peripheral advertisementData:advertisementData RSSI:RSSI];
    
    if (!device || ![device conformsToProtocol:@protocol(YMZBLEDeviceProtocol)] || ![device conformsToProtocol:@protocol(CBPeripheralDelegate)]) {
        return;
    }
    [self addDidDiscoverDevice:device];
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    
    id<YMZBLEDeviceProtocol> device = [self bleDeviceByIdentifier:peripheral.identifier.UUIDString];
    if (!device) {
        NSAssert(0, @"bleDeviceByIdentifier 方法有bug");
    }
    [self addDidConnictedDevice:device];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error {

    id<YMZBLEDeviceProtocol> device = [self bleDeviceByIdentifier:peripheral.identifier.UUIDString];
    [device didFailToConnect];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error {
    id<YMZBLEDeviceProtocol> device = [self bleDeviceByIdentifier:peripheral.identifier.UUIDString];
    [device didDisConnected];
}


dispatch_queue_t centralManagerDelegateQueue() {
    static dispatch_queue_t delegateQueue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        delegateQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    });
    return delegateQueue;
}
@end
