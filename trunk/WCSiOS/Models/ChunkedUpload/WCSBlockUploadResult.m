//
//  WCSMakeFileResult.m
//  WCSiOS
//
//  Created by mato on 16/4/26.
//  Copyright © 2016年 CNC. All rights reserved.
//

#import "WCSBlockUploadResult.h"

@interface WCSBlockUploadResult()

@property (nonatomic, strong) NSError *error;

@end

@implementation WCSBlockUploadResult

- (instancetype)initWithResponseData:(NSData *)data HTTPResponse:(NSHTTPURLResponse *)response error:(NSError **)error {
  if (self = [super init]) {
    NSError *jsonError;
    NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
    if (jsonError) {
      *error = [NSError errorWithDomain:WCSClientErrorDomain code:WCSClientErrorIllegalData userInfo:@{WCSErrorKey :[NSString stringWithFormat:@"Decode response as JSON failed.%@",response] }];
    } else {
      NSInteger statusCode = response.statusCode;
      if (statusCode >= 200 && statusCode < 300) {
        _results = responseDict;
        _error = *error;
      } else {
        NSDictionary *allHeaders = response.allHeaderFields;
        NSInteger code = [responseDict safeIntegerForKey:@"code"];
        NSString *message = [responseDict safeStringForKey:@"message"];
        NSString *reqid = [allHeaders safeStringForKey:@"X-Reqid"];

        *error = [NSError errorWithDomain:WCSServerErrorDomain code:code userInfo:@{WCSErrorKey : message, WCSxReqidErrorKey : reqid }];
        _error = *error;
      }
    }
  }
  return self;
}

@end
