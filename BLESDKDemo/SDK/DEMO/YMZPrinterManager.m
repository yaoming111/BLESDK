//
//  YMZPrinterManager.m
//  BLESDK
//
//  Created by Y@o on 2017/12/6.
//  Copyright © 2017年 Y@o. All rights reserved.
//

#import "YMZPrinterManager.h"
#import "YMZPrinter.h"

@interface YMZPrinterManager()<CHDBLEManagerDelegate, CHDBLEManagerDatasource>
@property (nonatomic, strong) YMZBLEManager *manager;

@end

@implementation YMZPrinterManager

- (instancetype)init {
    if (self = [super init]) {
        _manager = [[YMZBLEManager alloc] initWithDelegate:self datasource:self];
    }
    return self;
}

- (NSMutableArray<id<YMZBLEDeviceProtocol>> *)didDiscoverPeripherals {
    
    return self.manager.didDiscoverPeripherals;
}

#pragma mark - CHDBLEManagerDelegate
- (void)BLEManager:(YMZBLEManager *)BLEManager centralManagerDidUpdateState:(CBCentralManager *)central {
    
    [self.manager scanForPeripheralsWithServiceUUIDStrings:nil];
}

- (void)BLEManager:(YMZBLEManager *)BLEManager didDiscoverDevice:(id<YMZBLEDeviceProtocol, CBPeripheralDelegate>)device {
    //此处可以用来更新外设列表
}
#pragma mark - CHDBLEManagerDatasource

- (id<YMZBLEDeviceProtocol, CBPeripheralDelegate>)BLEManager:(YMZBLEManager *)BLEManager conversionCustomDeviceInstanceWithPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *, id> *)advertisementData RSSI:(NSNumber *)RSSI {
 
    YMZPrinter *device = [[YMZPrinter alloc]init];
    device.peripheral = peripheral;
    device.reconnect = YES;
    return device;
}
@end
