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

- (void)didReceiveReadRequest:(CBATTRequest *)request {

}

- (void)didReceiveWriteRequest:(CBATTRequest *)request {
    if ([self.delegate respondsToSelector:@selector(didReceiveData:)]) {
        NSData *data = request.value;
        NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        [self.delegate didReceiveData:string];
    }
}
@end
