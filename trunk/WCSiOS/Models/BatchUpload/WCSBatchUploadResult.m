//
//  WCSBatchUploadResult.m
//  WCSiOS
//
//  Created by mato on 16/4/11.
//  Copyright © 2016年 CNC. All rights reserved.
//

#import "WCSBatchUploadResult.h"
#import "NSDictionary+WCSDictionarySafeExtensions.h"

@implementation WCSBatchUploadResult

- (instancetype)initWithResponseData:(NSData *)data HTTPResponse:(NSHTTPURLResponse *)response error:(NSError *__autoreleasing *)error {
  if (self = [super init]) {
    NSUInteger statusCode = response.statusCode;
    if (statusCode >= 200 && statusCode < 300) {
      NSError *jsonError;
      NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
      if (jsonError) {
        *error = [NSError errorWithDomain:WCSClientErrorDomain code:WCSClientErrorIllegalData userInfo:@{WCSErrorKey :[NSString stringWithFormat:@"Decode response as JSON failed.%@",response] }];

      } else {
        WCSLogVerbose("batch upload response %@", responseDict);
        _successNum = [responseDict safeIntegerForKeyPath:@"brief.successNum"];
        _failedNum =  [responseDict safeIntegerForKeyPath:@"brief.failNum"];
        _detailArray = [responseDict safeArrayForKey:@"detail"];
      }
    } else {
      if (error) {
      *error = [NSError errorWithDomain:WCSClientErrorDomain code:WCSClientErrorIllegalData userInfo:@{WCSErrorKey : [NSString stringWithFormat:@"Status code %zd unexpected.", statusCode]}];
      }
    }
  }
  return self;
}

@end
