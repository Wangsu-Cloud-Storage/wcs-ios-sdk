//
//  NSURL+WCSParameters.m
//  WCSDemo
//
//  Created by mato on 14-8-4.
//  Copyright (c) 2014年 wcs. All rights reserved.
//

#import "NSURL+WCSParameters.h"

@implementation NSURL (WCSParameters)

- (NSURL *)URLByAppendingQueryString:(NSString *)queryString {
    if (![queryString length]) {
        return self;
    }
    
    NSString *URLString = [[NSString alloc] initWithFormat:@"%@%@%@", [self absoluteString], [self query] ? @"&" : @"?", queryString];
    NSURL *theURL = [NSURL URLWithString:URLString];
    return theURL;
}

- (NSURL *)URLByAppendingQueryParameters:(NSDictionary *)parameters {
    NSMutableString *queryString = [NSMutableString string];
    [parameters enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if([queryString length]){
            [queryString appendString:@"&"];
        }
        [queryString appendFormat:@"%@=%@", [key description], [obj description]];
    }];
    return [self URLByAppendingQueryString:queryString];
}

@end
