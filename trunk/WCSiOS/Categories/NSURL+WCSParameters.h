//
//  NSURL+WCSParameters.h
//  WCSDemo
//
//  Created by mato on 14-8-4.
//  Copyright (c) 2014年 wcs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURL (WCSParameters)

- (NSURL *)URLByAppendingQueryString:(NSString *)queryString;

- (NSURL *)URLByAppendingQueryParameters:(NSDictionary *)parameters;

@end
