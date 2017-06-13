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
 创建一个用于发起请求的Client

 @param baseURL 当前所使用的域名(必填)
 */
- (instancetype _Nonnull)initWithBaseURL:(NSURL * _Nullable)baseURL;

/**
 创建一个用于发起请求的Client
 
 @param baseURL 当前所使用的域名(必填)
 @param timeout 超时时间
 */
- (instancetype _Nonnull)initWithBaseURL:(NSURL * _Nullable )baseURL andTimeout:(NSTimeInterval)timeout;

/**
 创建一个用于发起请求的Client
 
 @param baseURL 当前所使用的域名(必填)
 @param timeout 超时时间
 @param concurrentCount 分片上传的并发数，范围为5~10。
 */
- (instancetype _Nullable )initWithBaseURL:(NSURL *_Nullable)baseURL
                                andTimeout:(NSTimeInterval)timeout
                           concurrentCount:(NSUInteger)concurrentCount;

/**
 创建一个用于发起请求的Client
 
 @param baseURL 当前所使用的域名(必填)
 @param timeout 超时时间
 @param concurrentCount 分片上传的并发数，范围为5~10。
 @param retryTimes 重试次数
 */
- (instancetype _Nonnull)initWithBaseURL:(NSURL * _Nullable)baseURL
                     andTimeout:(NSTimeInterval)timeout
                concurrentCount:(NSUInteger)concurrentCount
                     retryTimes:(NSUInteger)retryTimes;

/**
 创建一个用于发起请求的Client
 
 @param baseURL 当前所使用的域名(必填)
 @param timeout 超时时间
 @param proxyDictionary 设置代理字典。
 */
- (instancetype _Nonnull)initWithBaseURL:(NSURL *_Nullable)baseURL
                     andTimeout:(NSTimeInterval)timeout
                proxyDictionary:(NSDictionary *_Nullable)proxyDictionary;

/**
 *  上传一个文件
 *
 *  @param request 上传文件的request
 *
 */
- (WCSTask<WCSUploadObjectResult *> * _Nonnull)uploadRequest:(WCSUploadObjectRequest * _Nonnull)request;

/**
 上传一个文件

 @param request 上传文件的request
 @return 返回服务端返回的字符串
 */
- (WCSTask<WCSUploadObjectStringResult *> * _Nonnull)uploadRequestRaw:(WCSUploadObjectRequest * _Nonnull)request;

/**
 *  分片上传
 *
 *  @param blockRequest 分片上传的request
 *
 */
- (WCSTask<WCSBlockUploadResult *> * _Nonnull)blockUploadRequest:(WCSBlockUploadRequest * _Nonnull)blockRequest;

/**
 分片上传

 @param blockRequest 分片上传的request
 @return 返回格式为base64编码后的字符串
 */
- (WCSTask<WCSBlockUploadBase64Result *> * _Nonnull)blockUploadRequestRaw:(WCSBlockUploadRequest * _Nonnull)blockRequest;

@end
