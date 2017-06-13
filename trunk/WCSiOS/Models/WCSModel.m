//
//  WCSModel.m
//  WCSiOS
//
//  Created by mato on 16/3/25.
//  Copyright © 2016年 CNC. All rights reserved.
//

#import "WCSModel.h"

NSString * const WCSClientErrorDomain = @"com.chinanetcenter.clientError";
NSString * const WCSServerErrorDomain = @"com.chinanetcenter.serverError";

NSString * const WCSErrorKey = @"WCSErrorKey";
NSString * const WCSxReqidErrorKey = @"WCSxReqidErrorKey";
NSString * const WCSSubErrorsKey = @"WCSSubErrorsKey";


NSString * const WCSFormToken = @"token";
NSString * const WCSFormUploadFileKey = @"key";
NSString * const WCSFormUploadFile = @"file";
NSString * const WCSFormMimeType = @"mimeType";

NSString * const WCSPathForPut = @"/file/upload";
NSString * const WCSPathForMultipartUpload = @"/multifile/upload";

NSString * const WCSGetURLString = @"http://w.wcsapi.biz.matocloud.com";
NSString * const WCSBaseUploadString = @"your upload domain";
NSString * const WCSManagerURLString = @"http://mgr.wcsapi.biz.matocloud.com";
//NSString * const WCSBaseUploadString = @"https://apitestuser.up0.v1.wcsapi.com";
//NSString * const WCSManagerURLString = @"https://apitestuser.mgr0.v1.wcsapi.com";

@implementation WCSModel

@end
