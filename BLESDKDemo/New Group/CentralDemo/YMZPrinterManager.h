//
//  YMZPrinterManager.h
//  BLESDK
//
//  Created by Y@o on 2017/12/6.
//  Copyright © 2017年 Y@o. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YMZBLEHeader.h"

@class YMZPrinterManager;

@protocol YMZPrinterManagerDelegate <NSObject>

- (void)printerManager:(YMZPrinterManager *)printerManager didDiscoverDevice:(id<YMZBLEDeviceProtocol, CBPeripheralDelegate>)device;
@end

@interface YMZPrinterManager : NSObject

@property (nonatomic, weak) id<YMZPrinterManagerDelegate> delegate;
/*! 已搜索到的设备*/
@property (nonatomic, strong, readonly) NSMutableArray<id<YMZBLEDeviceProtocol>> *didDiscoverPeripherals;

- (instancetype)initWithDelegate:(id<YMZPrinterManagerDelegate>)delegate;
@end
