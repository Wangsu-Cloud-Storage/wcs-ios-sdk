//
//  WCSMakeBlockResult.m
//  WCSiOS
//
//  Created by mato on 16/4/25.
//  Copyright © 2016年 CNC. All rights reserved.
//

#import "WCSMakeBlockResult.h"

@interface WCSMakeBlockResult()

@property (nonatomic, strong, readonly) NSError *error;

@end

@implementation WCSMakeBlockResult

- (instancetype)initWithResponseData:(NSData *)data HTTPResponse:(NSHTTPURLResponse *)response error:(NSError *__autoreleasing *)error {
  if (self = [super init]) {
    NSError *jsonError;
    NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
    if (jsonError) {
      *error = [NSError errorWithDomain:WCSClientErrorDomain code:WCSClientErrorIllegalData userInfo:@{WCSErrorKey :[NSString stringWithFormat:@"Decode response as JSON failed.%@",response] }];
    } else {
      NSInteger statusCode = response.statusCode;
      if (statusCode >= 200 && statusCode < 300) {
        _context = [[responseDict safeStringForKey:@"ctx"] copy];
        _checksum = [[responseDict safeStringForKey:@"checksum"] copy];
        _crc32 = [responseDict safeIntegerForKey:@"crc32"];
        _offset = [responseDict safeLongLongForKey:@"offset"];
      } else {
        NSDictionary *allHeaders = response.allHeaderFields;
        NSString *reqid = [allHeaders safeStringForKey:@"X-Reqid"];
        NSInteger code = [responseDict safeIntegerForKey:@"code"];
        NSString *message = [responseDict safeStringForKey:@"message"];
        *error = [NSError errorWithDomain:WCSServerErrorDomain code:code userInfo:@{WCSErrorKey : message, WCSxReqidErrorKey : reqid }];
        _error = *error;
      }
    }
  }
  return self;
}

@end
