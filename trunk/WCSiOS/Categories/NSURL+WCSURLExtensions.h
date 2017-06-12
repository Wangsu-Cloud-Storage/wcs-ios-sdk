//
//  NSURL+WCSExtensions.h
//  WCS
//
//  Created by mato on 14-8-22.
//  Copyright (c) 2014年 DFP. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURL (WCSURLExtensions)

+ (NSURL *)URLWithFormat:(NSString *)formatString, ...;
+ (NSURL *)smartURLFromString:(NSString *)string;
- (NSURL *)URLByAppendingParams:(NSDictionary *)params;

@end
