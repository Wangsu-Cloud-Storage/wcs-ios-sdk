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

#import "WCSNetworking.h"
#import <UIKit/UIKit.h>
#import "WCSBolts.h"
#import "WCSURLSessionManager.h"
#import "WCSLogging.h"

NSString *const WCSNetworkingErrorDomain = @"com.chinanetcenter.WCSNetworkingErrorDomain";

#pragma mark - WCSHTTPMethod

@implementation NSString (WCSHTTPMethod)

+ (instancetype)wcs_stringWithHTTPMethod:(WCSHTTPMethod)HTTPMethod {
  NSString *string = nil;
  switch (HTTPMethod) {
    case WCSHTTPMethodGET:
      string = @"GET";
      break;
    case WCSHTTPMethodHEAD:
      string = @"HEAD";
      break;
    case WCSHTTPMethodPOST:
      string = @"POST";
      break;
    case WCSHTTPMethodPUT:
      string = @"PUT";
      break;
    case WCSHTTPMethodPATCH:
      string = @"PATCH";
      break;
    case WCSHTTPMethodDELETE:
      string = @"DELETE";
      break;
      
    default:
      break;
  }
  
  return string;
}

@end

#pragma mark - WCSNetworking

@interface WCSNetworking()

@property (nonatomic, strong) WCSURLSessionManager *networkManager;

@end

@implementation WCSNetworking

- (void)dealloc
{
  //networkManager will never be dealloc'ed if session had not been invalidated.
  NSURLSession * session = [_networkManager valueForKey:@"session"];
  if ([session isKindOfClass:[NSURLSession class]]) {
    [session finishTasksAndInvalidate];
  }
}

- (instancetype)init {
  @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                 reason:@"`- init` is not a valid initializer. Use `- initWithConfiguration` instead."
                               userInfo:nil];
  return nil;
}

- (instancetype)initWithConfiguration:(WCSNetworkingConfiguration *)configuration {
  if (self = [super init]) {
    _networkManager = [[WCSURLSessionManager alloc] initWithConfiguration:configuration];
  }
  
  return self;
}

- (WCSTask *)sendRequest:(WCSRequest *)request {
  WCSTaskCompletionSource *taskCompletionSource = [WCSTaskCompletionSource taskCompletionSource];
  [self.networkManager dataTaskWithRequest:request
                         completionHandler:^(id responseObject, NSError *error) {
                           if (!error) {
                             taskCompletionSource.result = responseObject;
                           } else {
                             [taskCompletionSource setError:error];
                           }
                         }];
  
  return taskCompletionSource.task;
}
@end

#pragma mark - WCSNetworkingConfiguration

@implementation WCSNetworkingConfiguration

- (instancetype)init {
  if (self = [super init]) {
    _maxRetryCount = 3;
    _allowsCellularAccess = YES;
  }
  return self;
}

- (NSURL *)URL {
  //    // You can overwrite the URL by providing a full URL in URLString.
  //    NSURL *fullURL = [NSURL URLWithString:self.URLString];
  //    if ([fullURL.scheme isEqualToString:@"http"]
  //        || [fullURL.scheme isEqualToString:@"https"]) {
  //        NSMutableDictionary *headers = [self.headers mutableCopy];
  //        headers[@"Host"] = [fullURL host];
  //        self.headers = headers;
  //        return fullURL;
  //    }
  //
  //    if (!self.URLString) {
  //        return self.baseURL;
  //    }
  //
  //    return [NSURL URLWithString:self.URLString
  //                  relativeToURL:self.baseURL];
  return nil;
}

- (void)setMaxRetryCount:(uint32_t)maxRetryCount {
  // the max maxRetryCount is 10. If set to higher than that, it becomes 10.
  if (maxRetryCount > 10) {
    _maxRetryCount = 10;
  } else {
    _maxRetryCount = maxRetryCount;
  }
}

- (id)copyWithZone:(NSZone *)zone {
  
  WCSNetworkingConfiguration *configuration = [[[self class] allocWithZone:zone] init];
  configuration.baseURL = [self.baseURL copy];
  configuration.URLString = [self.URLString copy];
  configuration.HTTPMethod = self.HTTPMethod;
  configuration.headers = [self.headers copy];
  configuration.allowsCellularAccess = self.allowsCellularAccess;
  configuration.retryHandler = self.retryHandler;
  configuration.maxRetryCount = self.maxRetryCount;
  configuration.timeoutIntervalForRequest = self.timeoutIntervalForRequest;
  configuration.timeoutIntervalForResource = self.timeoutIntervalForResource;
  
  return configuration;
}

@end

#pragma mark - WCSNetworkingRequest

@interface WCSNetworkingRequest()

@property (nonatomic, strong) NSURLSessionTask *task;
@property (nonatomic, assign, getter = isCancelled) BOOL cancelled;

@end

@implementation WCSNetworkingRequest

- (void)assignProperties:(WCSNetworkingConfiguration *)configuration {
  if (!self.baseURL) {
    self.baseURL = configuration.baseURL;
  }
  
  if (!self.URLString) {
    self.URLString = configuration.URLString;
  }
  
  if (!self.HTTPMethod) {
    self.HTTPMethod = configuration.HTTPMethod;
  }
  
  if (configuration.headers) {
    NSMutableDictionary *mutableCopy = [configuration.headers mutableCopy];
    [self.headers enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
      [mutableCopy setObject:obj forKey:key];
    }];
    self.headers = mutableCopy;
  }
  
  if (!self.retryHandler) {
    self.retryHandler = configuration.retryHandler;
  }
}

- (void)setTask:(NSURLSessionTask *)task {
  @synchronized(self) {
    if (!_cancelled) {
      _task = task;
    } else {
      _task = nil;
    }
  }
}

- (BOOL)isCancelled {
  @synchronized(self) {
    return _cancelled;
  }
}

- (void)cancel {
  @synchronized(self) {
    if (!_cancelled) {
      _cancelled = YES;
      [self.task cancel];
    }
  }
}

- (void)pause {
  @synchronized(self) {
    [self.task cancel];
  }
}

@end

@interface WCSRequest()

@property (nonatomic, strong) WCSNetworkingRequest *internalRequest;
@property (nonatomic, assign) NSNumber *shouldWriteDirectly;

@end

@implementation WCSRequest

- (instancetype)init {
  if (self = [super init]) {
    _internalRequest = [WCSNetworkingRequest new];
  }
  
  return self;
}

- (WCSTask *)constructSessionTaskUsingSession:(NSURLSession *)session baseURL:(NSURL *)baseURL {
  return [WCSTask taskWithError:[NSError errorWithDomain:WCSNetworkingErrorDomain code:WCSNetworkingErrorUnknown userInfo:@{NSLocalizedDescriptionKey : @"constructSessionTaskUsingSession must overide in subclass."}]];
}

- (void)setUploadProgress:(WCSNetworkingUploadProgressBlock)uploadProgress {
  self.internalRequest.uploadProgress = uploadProgress;
}

- (void)setDecreaseProgress:(void (^)(int64_t bytesReverted))decreaseProgress {
  self.internalRequest.decreaseBlock = decreaseProgress;
}

- (void)setDownloadProgress:(WCSNetworkingDownloadProgressBlock)downloadProgress {
  self.internalRequest.downloadProgress = downloadProgress;
}

- (BOOL)isCancelled {
  return [self.internalRequest isCancelled];
}

- (WCSTask *)cancel {
  [self.internalRequest cancel];
  return [WCSTask taskWithResult:nil];
}

- (WCSTask *)pause {
  [self.internalRequest pause];
  return [WCSTask taskWithResult:nil];
}

@end
