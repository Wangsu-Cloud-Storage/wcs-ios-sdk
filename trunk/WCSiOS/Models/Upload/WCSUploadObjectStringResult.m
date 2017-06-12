//
//  WCSUploadObjectStringResult.m
//  TestWCSiOS
//
//  Created by mato on 2016/11/17.
//  Copyright © 2016年 CNC. All rights reserved.
//

#import "WCSUploadObjectStringResult.h"
#import "WCSLogging.h"

@interface WCSUploadObjectStringResult()

@property (nonatomic, strong) NSError *error;

@end

@implementation WCSUploadObjectStringResult

- (instancetype)initWithResponseData:(NSData *)data HTTPResponse:(NSHTTPURLResponse *)response error:(NSError *__autoreleasing *)error{
  if (self = [super init]) {
    NSInteger statusCode = response.statusCode;
    NSString* responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (statusCode >= 200 && statusCode <= 299) {
        _resultString = [responseString copy];
    } else {
      NSError *jsonError;
      NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
      if (jsonError) {
        WCSLogError("decode %@ as json failed.", responseString);
        *error = [NSError errorWithDomain:WCSClientErrorDomain code:WCSClientErrorIllegalData userInfo:@{WCSErrorKey : @"Decode as JSON failed."}];
        _error = *error;
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
