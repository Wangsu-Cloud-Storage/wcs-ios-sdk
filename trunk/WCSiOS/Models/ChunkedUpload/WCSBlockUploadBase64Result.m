//
//  WCSBlockUploadBase64Result.m
//  TestWCSiOS
//
//  Created by mato on 2016/11/18.
//  Copyright © 2016年 CNC. All rights reserved.
//

#import "WCSBlockUploadBase64Result.h"
#import "WCSGTMStringEncoding.h"

@interface WCSBlockUploadBase64Result()

@end

@implementation WCSBlockUploadBase64Result

- (instancetype)initWithJSONDiction:(NSDictionary *)JSONDictionary {
  if (self = [super init]) {
    if (JSONDictionary) {
      NSMutableString *rawString = [NSMutableString stringWithString:@""];
      [JSONDictionary enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([rawString isEqualToString:@""]) {
          [rawString appendFormat:@"%@=%@", key, obj];
        } else {
          [rawString appendFormat:@"&%@=%@", key, obj];
        }
        NSString *encodedString = [[WCSGTMStringEncoding rfc4648Base64WebsafeStringEncoding] encodeString:rawString];
        _resultString = [encodedString copy];
      }];
    }
  }
  return self;
}

@end
