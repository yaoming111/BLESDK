//
//  YMZPrinterManager.h
//  BLESDK
//
//  Created by Y@o on 2017/12/6.
//  Copyright © 2017年 Y@o. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YMZBLEHeader.h"

@interface YMZPrinterManager : NSObject
/*! 已搜索到的设备*/
@property (nonatomic, strong, readonly) NSMutableArray<id<YMZBLEDeviceProtocol>> *didDiscoverPeripherals;
@end
