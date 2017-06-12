//
//  WCSTimeoutRetryHandler.h
//  WCSiOS
//
//  Created by mato on 2017/2/16.
//  Copyright © 2017年 CNC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WCSNetworking.h"

@interface WCSTimeoutRetryHandler : NSObject<WCSURLRequestRetryHandler>

@property (nonatomic, assign, readonly) NSUInteger retryTimes;

- (instancetype)initWithRetryTimes:(NSUInteger)retryTimes;

@end
