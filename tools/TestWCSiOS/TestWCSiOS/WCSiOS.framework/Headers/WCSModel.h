//
//  WCSModel.h
//  WCSiOS
//
//  Created by mato on 16/3/25.
//  Copyright © 2016年 CNC. All rights reserved.
//

#import "WCSNetworking.h"
#import "WCSBolts.h"
#import "WCSLogging.h"
#import "NSDictionary+WCSDictionarySafeExtensions.h"
#import "WCSCommonAlgorithm.h"

FOUNDATION_EXPORT NSString * const WCSClientErrorDomain;
FOUNDATION_EXPORT NSString * const WCSServerErrorDomain;

FOUNDATION_EXPORT NSString * const WCSErrorKey;
FOUNDATION_EXPORT NSString * const WCSSubErrorsKey;

FOUNDATION_EXPORT NSString * const WCSFormToken;
FOUNDATION_EXPORT NSString * const WCSFormUploadFileKey;
FOUNDATION_EXPORT NSString * const WCSFormUploadFile;
FOUNDATION_EXPORT NSString * const WCSFormMimeType;

FOUNDATION_EXPORT NSString * const WCSBaseUploadString;
FOUNDATION_EXPORT NSString * const WCSManagerURLString;
FOUNDATION_EXPORT NSString * const WCSGetURLString;

FOUNDATION_EXPORT NSString * const WCSPathForPut;
FOUNDATION_EXPORT NSString * const WCSPathForMultipartUpload;

FOUNDATION_EXPORT NSString * const WCSReturnBodyBucket;
FOUNDATION_EXPORT NSString * const WCSReturnBodyKey;
FOUNDATION_EXPORT NSString * const WCSReturnBodyFName;
FOUNDATION_EXPORT NSString * const WCSReturnBodyHash;
FOUNDATION_EXPORT NSString * const WCSReturnBodyFSize;
FOUNDATION_EXPORT NSString * const WCSReturnBodyURL;
FOUNDATION_EXPORT NSString * const WCSReturnBodyIP;

typedef NS_ENUM(NSInteger, WCSClientError) {
  WCSClientErrorUnknown,
  WCSClientErrorInvalidateParameter
};

@interface WCSModel : WCSRequest

@end
