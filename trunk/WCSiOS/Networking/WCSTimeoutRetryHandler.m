//
//  WCSTimeoutRetryHandler.m
//  WCSiOS
//
//  Created by mato on 2017/2/16.
//  Copyright © 2017年 CNC. All rights reserved.
//

#import "WCSTimeoutRetryHandler.h"
#import "WCSLogging.h"

static NSTimeInterval const kMaxRetryInterval = 3;

@implementation WCSTimeoutRetryHandler

- (instancetype)initWithRetryTimes:(NSUInteger)retryTimes {
  if (self = [super init]) {
    _retryTimes = retryTimes;
  }
  return self;
}

- (WCSNetworkingRetryType)shouldRetry:(uint32_t)currentRetryCount
                             response:(NSHTTPURLResponse *)response
                       responseObject:(id)data
                                error:(NSError *)error {
  WCSLogDebug(@"Error occured %zd, %@", error.code, error.localizedDescription);
  if (currentRetryCount >= 3) {
    return WCSNetworkingRetryTypeShouldNotRetry;
  }
  
  if (error.code == NSURLErrorTimedOut || response.statusCode == 500 || response.statusCode == 408) {
    return WCSNetworkingRetryTypeShouldRetry;
  }
  
  return WCSNetworkingRetryTypeShouldNotRetry;
}

- (NSTimeInterval)timeIntervalForRetry:(uint32_t)currentRetryCount
                              response:(NSHTTPURLResponse *)response
                                  data:(NSData *)data
                                 error:(NSError *)error {
  return MIN(0.2 * pow(2, currentRetryCount - 1), kMaxRetryInterval);
}

@end
