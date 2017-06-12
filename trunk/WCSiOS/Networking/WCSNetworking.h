//
// Copyright 2010-2016 Amazon.com, Inc. or its affiliates. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.
// A copy of the License is located at
//
// http://aws.amazon.com/apache2.0
//
// or in the "license" file accompanying this file. This file is distributed
// on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
// express or implied. See the License for the specific language governing
// permissions and limitations under the License.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString *const WCSNetworkingErrorDomain;
typedef NS_ENUM(NSInteger, WCSNetworkingErrorType) {
    WCSNetworkingErrorUnknown,
    WCSNetworkingErrorCancelled
};

typedef NS_ENUM(NSInteger, WCSNetworkingRetryType) {
    WCSNetworkingRetryTypeUnknown,
    WCSNetworkingRetryTypeShouldNotRetry,
    WCSNetworkingRetryTypeShouldRetry
};

@class WCSNetworkingConfiguration;
@class WCSNetworkingRequest;
@class WCSTask<__covariant ResultType>;

typedef void (^WCSNetworkingUploadProgressBlock) (int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend);
typedef void (^WCSNetworkingUploadProgressDecreaseBlock) (int64_t bytesReverted);
typedef void (^WCSNetworkingDownloadProgressBlock) (int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite);
typedef void (^WCSNetworkingCompletionHandlerBlock)(id responseObject, NSError *error);

#pragma mark - WCSHTTPMethod

typedef NS_ENUM(NSInteger, WCSHTTPMethod) {
    WCSHTTPMethodUnknown,
    WCSHTTPMethodGET,
    WCSHTTPMethodHEAD,
    WCSHTTPMethodPOST,
    WCSHTTPMethodPUT,
    WCSHTTPMethodPATCH,
    WCSHTTPMethodDELETE
};

typedef NS_ENUM(NSInteger, WCSURLSessionTaskType) {
  WCSURLSessionTaskTypeUnknown,
  WCSURLSessionTaskTypeData,
  WCSURLSessionTaskTypeDownload,
  WCSURLSessionTaskTypeUpload
};

@interface NSString (WCSHTTPMethod)

+ (instancetype)wcs_stringWithHTTPMethod:(WCSHTTPMethod)HTTPMethod;

@end

#pragma mark - WCSNetworking

@class WCSRequest;

@interface WCSNetworking : NSObject

- (instancetype)initWithConfiguration:(WCSNetworkingConfiguration *)configuration;

- (WCSTask *)sendRequest:(WCSRequest *)request;

@end

#pragma mark - Protocols

@protocol WCSRequestModelSerializer <NSObject>

@required
- (WCSTask *)constructSessionTaskUsingSession:(NSURLSession *)session baseURL:(NSURL *)baseURL;

@end

@protocol WCSResponseModelSerializer <NSObject>

@required
- (instancetype)initWithResponseData:(NSData *)data HTTPResponse:(NSHTTPURLResponse *)response error:(NSError **)error;

@end

@protocol WCSURLRequestRetryHandler <NSObject>

@required

//@property (nonatomic, assign) uint32_t maxRetryCount;

- (WCSNetworkingRetryType)shouldRetry:(uint32_t)currentRetryCount
                            response:(NSHTTPURLResponse *)response
                       responseObject:(id)data
                               error:(NSError *)error;
@optional

- (NSTimeInterval)timeIntervalForRetry:(uint32_t)currentRetryCount
                              response:(NSHTTPURLResponse *)response
                                  data:(NSData *)data
                                 error:(NSError *)error;

@end


#pragma mark - WCSNetworkingConfiguration

@interface WCSNetworkingConfiguration : NSObject <NSCopying>

@property (nonatomic, readonly) NSURL *URL;
@property (nonatomic, strong) NSURL *baseURL;
@property (nonatomic, strong) NSString *URLString;
@property (nonatomic, assign) WCSHTTPMethod HTTPMethod;
@property (nonatomic, strong) NSDictionary *headers;
@property (nonatomic, assign) BOOL allowsCellularAccess;
@property (nonatomic, strong) NSDictionary *proxyDictionary;

@property (nonatomic, strong) id<WCSURLRequestRetryHandler> retryHandler;

/**
 The maximum number of retries for failed requests. The value needs to be between 0 and 10 inclusive. If set to higher than 10, it becomes 10.
 */
@property (nonatomic, assign) uint32_t maxRetryCount;

/**
 The timeout interval to use when waiting for additional data.
 */
@property (nonatomic, assign) NSTimeInterval timeoutIntervalForRequest;

/**
 The maximum amount of time that a resource request should be allowed to take.
 */
@property (nonatomic, assign) NSTimeInterval timeoutIntervalForResource;

@end

#pragma mark - WCSNetworkingRequest

@interface WCSNetworkingRequest : WCSNetworkingConfiguration

@property (nonatomic, assign) Class ouptutClass;
@property (nonatomic, assign) UInt64 transferBytes;

@property (nonatomic, copy) WCSNetworkingUploadProgressBlock uploadProgress;
@property (nonatomic, copy) WCSNetworkingUploadProgressDecreaseBlock decreaseBlock;
@property (nonatomic, copy) WCSNetworkingDownloadProgressBlock downloadProgress;

@property (readonly, nonatomic, strong) NSURLSessionTask *task;
@property (readonly, nonatomic, assign, getter = isCancelled) BOOL cancelled;

- (void)assignProperties:(WCSNetworkingConfiguration *)configuration;
- (void)cancel;
- (void)pause;

@end

@interface WCSRequest : NSObject<WCSRequestModelSerializer>

//@property (nonatomic, copy) WCSNetworkingUploadProgressBlock uploadProgress;
//@property (nonatomic, copy) WCSNetworkingDownloadProgressBlock downloadProgress;
@property (nonatomic, assign, readonly, getter = isCancelled) BOOL cancelled;

- (void)setUploadProgress:(void (^)(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend))uploadProgress;
- (void)setDecreaseProgress:(void (^)(int64_t bytesReverted))decreaseProgress;
- (void)setDownloadProgress:(void (^)(int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite))downloadProgress;

- (WCSTask *)cancel;
- (WCSTask *)pause;

@end
