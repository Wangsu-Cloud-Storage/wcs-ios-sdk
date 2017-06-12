//
//  WCSClient.h
//  WCSiOS
//
//  Created by mato on 16/3/24.
//  Copyright © 2016年 CNC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WCSBolts.h"
#import "WCSUploadObjectRequest.h"
#import "WCSUploadObjectResult.h"
#import "WCSUploadObjectStringResult.h"
#import "WCSBlockUploadBase64Result.h"
#import "WCSBlockUploadRequest.h"
#import "WCSBlockUploadResult.h"
#import "WCSApi.h"

FOUNDATION_EXPORT NSString * _Nonnull const WCSiOSSDKVersion;

@interface WCSClient : NSObject

@property (nonatomic, copy, readonly, nullable) NSURL *baseURL;
@property (nonatomic, assign, readonly) NSTimeInterval timeout;

/**
 *  创建一个用于发起请求的Client
 *
 *  @param baseURL 当前所使用的域名，默认使用http://up.wcsapi.biz.matocloud.com:8090
 *  @param timeout 超时时间
 */
- (instancetype _Nonnull)initWithBaseURL:(NSURL * _Nullable )baseURL andTimeout:(NSTimeInterval)timeout;

/**
 *  上传一个文件
 *
 *  @param request 上传文件的request
 *
 *  @return
 */
- (WCSTask<WCSUploadObjectResult *> * _Nonnull)uploadRequest:(WCSUploadObjectRequest * _Nonnull)request;

/**
 上传一个文件

 @param request 上传文件的request
 @return 返回格式为base64编码后的字符串
 */
- (WCSTask<WCSUploadObjectStringResult *> * _Nonnull)uploadRequestRaw:(WCSUploadObjectRequest * _Nonnull)request;

/**
 *  分片上传
 *
 *  @param blockRequest 分片上传的request
 *
 *  @return
 */
- (WCSTask<WCSBlockUploadResult *> * _Nonnull)blockUploadRequest:(WCSBlockUploadRequest * _Nonnull)blockRequest;

/**
 分片上传

 @param blockRequest 分片上传的request
 @return 返回格式为base64编码后的字符串
 */
- (WCSTask<WCSBlockUploadBase64Result *> * _Nonnull)blockUploadRequestRaw:(WCSBlockUploadRequest * _Nonnull)blockRequest;

@end
