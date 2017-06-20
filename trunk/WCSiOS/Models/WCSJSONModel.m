//
//  WCSJSONModel.m
//  WCSiOS
//
//  Created by mato on 16/5/3.
//  Copyright © 2016年 CNC. All rights reserved.
//

#import "WCSJSONModel.h"

@implementation WCSJSONModel

- (instancetype)initWithJSONData:(NSDictionary *)JSONData HTTPResponse:(NSHTTPURLResponse *)response error:(NSError **)error {
  @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                 reason:@"`- initWithJSONData:HTTPResponse:error` must override in subclass."
                               userInfo:nil];
  return nil;
}

- (instancetype)initWithResponseData:(NSData *)data HTTPResponse:(NSHTTPURLResponse *)response error:(NSError **)error {
  NSError *jsonError;
  NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
  if (jsonError) {
    *error = [NSError errorWithDomain:WCSClientErrorDomain code:WCSClientErrorIllegalData userInfo:@{WCSErrorKey :[NSString stringWithFormat:@"Decode response as JSON failed.%@",response] }];

  } else {
    return [self initWithJSONData:responseDict HTTPResponse:response error:error];
  }
  return nil;
}

@end
