//
//  WCSWCSPutObjectResult.m
//  WCSiOS
//
//  Created by mato on 16/3/25.
//  Copyright © 2016年 CNC. All rights reserved.
//

#import "WCSUploadObjectResult.h"
#import "WCSGTMStringEncoding.h"
#import "WCSLogging.h"
#import "NSDictionary+WCSDictionarySafeExtensions.h"

@interface WCSUploadObjectResult()

@property (nonatomic, strong) NSError *error;

@end

@implementation WCSUploadObjectResult

- (instancetype)initWithResponseData:(NSData *)data HTTPResponse:(NSHTTPURLResponse *)response error:(NSError *__autoreleasing *)error{
  if (self = [super init]) {
    NSInteger statusCode = response.statusCode;
    NSString* responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (statusCode >= 200 && statusCode <= 299) {
      NSMutableDictionary *decodeDict = [NSMutableDictionary dictionary];
      if(responseString && responseString.length > 0){
        NSString *decodeString = [[WCSGTMStringEncoding rfc4648Base64WebsafeStringEncoding] stringByDecoding:responseString];
        WCSLogDebug(@"upload request result string %@", decodeString);
        NSArray *responseValueKeyMaps = [decodeString componentsSeparatedByString:@"&"];
        for (NSString *responseValueKeyMap in responseValueKeyMaps) {
          NSRange range = [responseValueKeyMap rangeOfString:@"=" options:NSLiteralSearch];
          if (range.location != NSNotFound) {
            [decodeDict setObject:[responseValueKeyMap substringFromIndex:(range.location + 1)] forKey:[responseValueKeyMap substringToIndex:range.location]];
          }
        }
        _results = decodeDict;
      }
    } else {
      if (!data) {
        if (error) {
          *error = [NSError errorWithDomain:WCSServerErrorDomain code:response.statusCode userInfo:nil];
        }
      } else {
        NSError *jsonError = nil;
        NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        if (jsonError) {
          WCSLogError("decode %@ as json failed.", responseString);
          if (error) {
          *error = [NSError errorWithDomain:WCSClientErrorDomain code:WCSClientErrorIllegalData userInfo:@{WCSErrorKey : @"Decode as JSON failed."}];
          _error = *error;
          }
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
  }
  return self;
}

@end
