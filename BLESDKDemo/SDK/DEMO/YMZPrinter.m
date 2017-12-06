//
//  YMZPrinter.m
//  BLESDK
//
//  Created by Y@o on 2017/12/6.
//  Copyright © 2017年 Y@o. All rights reserved.
//

#import "YMZPrinter.h"

#define UUIDSTR_ISSC_PROPRIETARY_SERVICE @"49535343-FE7D-4AE5-8FA9-9FAFD205E455"
#define UUIDSTR_ISSC_TRANS_TX @"49535343-8841-43F4-A8D4-ECBE34729BB3" //发
#define UUIDSTR_ISSC_TRANS_RX @"49535343-1E4D-4BD9-BA61-23C647249616" //收

@implementation YMZPrinter{
    CBCharacteristic *_transTxCharacteristic; //发送特征
    CBCharacteristic *_transRxCharacteristic; //接收特征
}

- (void)subcontractWriteValue:(NSData *_Nonnull)data writeDataBlock:(YMZWriteDataBlock _Nullable)writeDataBlock {
    
    [self subcontractWriteValueToCharacteristic:_transTxCharacteristic value:data writeDataBlock:writeDataBlock];
}

- (void)writeCommand:(NSData *_Nonnull)command writeDataBlock:(YMZWriteDataBlock _Nullable)writeDataBlock responseBlock:(YMZResponseBlock _Nullable)responseBlock {
    
    [self writeCommandToCharacteristic:_transTxCharacteristic command:command writeDataBlock:writeDataBlock responseBlock:responseBlock];
}

#pragma mark - 必要协议方法
- (void)configCharacteristicsWithService:(CBService *_Nonnull)service {
    
    if ([service.UUID.UUIDString isEqualToString:UUIDSTR_ISSC_PROPRIETARY_SERVICE]) {
        for (CBCharacteristic *characteristic in service.characteristics) {
            
            if ([characteristic.UUID.UUIDString isEqualToString:UUIDSTR_ISSC_TRANS_TX]) {
                _transTxCharacteristic = characteristic;
                continue;
            }
            
            if ([characteristic.UUID.UUIDString isEqualToString:UUIDSTR_ISSC_TRANS_RX]) {
                _transRxCharacteristic = characteristic;
            }
        }
    }
}

@end
