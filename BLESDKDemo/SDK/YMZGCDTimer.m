//
//  YMZGCDTimer.m
//  BLESDK
//
//  Created by Y@o on 2017/12/6.
//  Copyright © 2017年 Y@o. All rights reserved.
//

#import "YMZGCDTimer.h"

@implementation YMZGCDTimer

+ (dispatch_source_timer_t)GCD_StartTimerWithTimeInterval:(NSTimeInterval)interval repeats:(BOOL)repeats block:(void (^)(void))block {
    __block NSInteger count = repeats ? NSIntegerMax : 1; //时间
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_source_timer_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    
    dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, interval * NSEC_PER_SEC, 0);
    
    dispatch_source_set_event_handler(timer, ^{
        
        if (count <= 0) {
            dispatch_source_cancel(timer);
            
            if (block) {
                block();
            }
        } else {
            count--;
        }
    });
    
    dispatch_resume(timer);
    
    return timer;
}

+ (void)GCD_CancelTimer:(dispatch_source_timer_t)GCDTimer {
    if (!GCDTimer) {
        return;
    }
    dispatch_source_cancel(GCDTimer);
}
@end
