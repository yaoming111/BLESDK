//
//  YMZDisplayServiceManager.m
//  BLESDKDemo
//
//  Created by Y@o on 2017/12/6.
//  Copyright © 2017年 Y@o. All rights reserved.
//

#import "YMZDisplayServiceManager.h"

#define kDisplayServiceUUIDString @"FFF0"

#define kDisplayCharacteristic_TX @"FFF1"
#define kDisplayCharacteristic_RX @"FFF2"

@implementation YMZDisplayServiceManager

- (void)initService {
    self.service = [[CBMutableService alloc]initWithType:[CBUUID UUIDWithString:kDisplayServiceUUIDString] primary:YES];
    CBMutableCharacteristic *tx_characteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:kDisplayCharacteristic_TX] properties:CBCharacteristicPropertyWrite value:nil permissions:CBAttributePermissionsWriteable];
    CBMutableCharacteristic *rx_characteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:kDisplayCharacteristic_RX] properties:CBCharacteristicPropertyRead value:nil permissions:CBAttributePermissionsReadable];
    
    self.service.characteristics = @[tx_characteristic, rx_characteristic];
}

- (void)central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic {

}

- (void)central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic {

}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request {

    if (request.characteristic.properties & CBCharacteristicPropertyRead) {
        
        NSData *data = request.characteristic.value;
        //处理命令并组织返回值
        NSData *respondData = [@"19910314" dataUsingEncoding:NSUTF8StringEncoding];

        [request setValue:respondData];
        //对请求作出成功响应
        [peripheral respondToRequest:request withResult:CBATTErrorSuccess];
        
    }else {
        
        [peripheral respondToRequest:request withResult:CBATTErrorWriteNotPermitted];
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequest:(CBATTRequest *)request {
    
    if ([self.delegate respondsToSelector:@selector(didReceiveData:)]) {
        NSData *data = request.value;
        NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        [self.delegate didReceiveData:string];
        [peripheral respondToRequest:request withResult:CBATTErrorSuccess];
    }
}
@end
