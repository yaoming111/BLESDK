//
//  YMZGCDTimer.h
//  BLESDK
//
//  Created by Y@o on 2017/12/6.
//  Copyright © 2017年 Y@o. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef dispatch_source_t dispatch_source_timer_t;

@interface YMZGCDTimer : NSObject
/*! 创建并启动一个定时器 并返回定时器实例*/
+ (dispatch_source_timer_t)GCD_StartTimerWithTimeInterval:(NSTimeInterval)interval repeats:(BOOL)repeats block:(void (^)(void))block;
/*! 停用并销毁定时器*/
+ (void)GCD_CancelTimer:(dispatch_source_timer_t)GCDTimer;
@end
