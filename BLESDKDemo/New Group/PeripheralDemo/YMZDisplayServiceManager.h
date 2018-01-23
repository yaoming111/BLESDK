//
//  YMZDisplayServiceManager.h
//  BLESDKDemo
//
//  Created by Y@o on 2017/12/6.
//  Copyright © 2017年 Y@o. All rights reserved.
//

#import "YMZBaseServiceManager.h"

@protocol YMZDisplayServiceManagerDelegate<NSObject>

- (void)didReceiveData:(NSString *)string;
@end

@interface YMZDisplayServiceManager : YMZBaseServiceManager

@property (nonatomic, weak) id<YMZDisplayServiceManagerDelegate> delegate;
@end
