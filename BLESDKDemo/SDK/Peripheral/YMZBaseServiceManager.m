//
//  YMZBaseServiceManager.m
//  BLESDKDemo
//
//  Created by Y@o on 2017/12/6.
//  Copyright © 2017年 Y@o. All rights reserved.
//

#import "YMZBaseServiceManager.h"

@implementation YMZBaseServiceManager

@synthesize service;

- (instancetype)init {
    if (self = [super init]) {
        [self initService];
    }
    return self;
}

- (void)initService {
    NSAssert(0, @"子类必须实现并正确配置");
}

- (void)central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic {

}

- (void)central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic {

}

- (void)didReceiveReadRequest:(CBATTRequest *)request {
    
}

- (void)didReceiveWriteRequest:(CBATTRequest *)request {
    
}

@end
