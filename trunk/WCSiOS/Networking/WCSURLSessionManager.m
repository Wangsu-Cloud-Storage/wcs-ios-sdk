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

#import "WCSURLSessionManager.h"

#import "WCSLogging.h"
#import "WCSDefines.h"
#import "WCSBolts.h"
#import "WCSThreadSafeMutableDictionary.h"
#import <UIKit/UIKit.h>
#import "sys/utsname.h"
#pragma mark - WCSURLSessionManagerDelegate

static NSString* const WCSMobileURLSessionManagerCacheDomain = @"com.chinanetcenter.WCSURLSessionManager";

@interface WCSURLSessionManagerDelegate : NSObject

@property (nonatomic, assign) WCSURLSessionTaskType taskType;
@property (nonatomic, copy) WCSNetworkingCompletionHandlerBlock dataTaskCompletionHandler;
@property (nonatomic, strong) WCSRequest *request;
@property (nonatomic, strong) NSURL *uploadingFileURL;
@property (nonatomic, strong) NSURL *downloadingFileURL;

@property (nonatomic, assign) uint32_t currentRetryCount;
@property (nonatomic, strong) NSError *error;
@property (nonatomic, strong) id responseObject;
@property (nonatomic, strong) NSMutableData *responseData;
@property (nonatomic, strong) NSFileHandle *responseFilehandle;
@property (nonatomic, strong) NSURL *tempDownloadedFileURL;
@property (nonatomic, assign) BOOL shouldWriteDirectly;
@property (nonatomic, assign) BOOL shouldWriteToFile;

@property (atomic, assign) int64_t lastTotalLengthOfChunkSignatureSent;
@property (atomic, assign) int64_t payloadTotalBytesWritten;
@property (atomic, assign) int64_t countOfByteSent;

@end

@implementation WCSURLSessionManagerDelegate

- (instancetype)init {
  if (self = [super init]) {
    _taskType = WCSURLSessionTaskTypeUnknown;
  }
  
  return self;
}

@end

@interface WCSRequest()

@property (nonatomic, strong) WCSNetworkingRequest *internalRequest;

@end

#pragma mark - WCSNetworkingRequest

@interface WCSNetworkingRequest()

@property (nonatomic, strong) NSURLSessionTask *task;

@end

#pragma mark - WCSURLSessionManager

//const int64_t WCSMinimumDownloadTaskSize = 1000000;

@interface WCSURLSessionManager()

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) WCSThreadSafeMutableDictionary *sessionManagerDelegates;

@end

@implementation WCSURLSessionManager

- (instancetype)init {
  @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                 reason:@"`- init` is not a valid initializer. Use `- initWithConfiguration` instead."
                               userInfo:nil];
  return nil;
}

- (instancetype)initWithConfiguration:(WCSNetworkingConfiguration *)configuration {
  if (self = [super init]) {
    _configuration = configuration;
    
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfiguration.URLCache = nil;
    if ([configuration.proxyDictionary count]>0 && configuration.proxyDictionary != nil) {
      sessionConfiguration.connectionProxyDictionary = configuration.proxyDictionary;
    }
    if (configuration.timeoutIntervalForRequest > 0) {
      sessionConfiguration.timeoutIntervalForRequest = configuration.timeoutIntervalForRequest;
    }
    sessionConfiguration.allowsCellularAccess = configuration.allowsCellularAccess;
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *platform = [NSString stringWithCString:systemInfo.machine encoding:NSASCIIStringEncoding];
    NSString *userAgent = [NSString stringWithFormat:@"WCS-iOS-SDK-%@-%@-iOS%@(https://www.chinanetcenter.com)", WCS_IOS_VERSION,platform,[[UIDevice currentDevice] systemVersion]];
    sessionConfiguration.HTTPAdditionalHeaders = @{@"User-Agent": userAgent};
    _session = [NSURLSession sessionWithConfiguration:sessionConfiguration
                                             delegate:self
                                        delegateQueue:nil];
    _sessionManagerDelegates = [[WCSThreadSafeMutableDictionary alloc] init];
  }
  
  return self;
}

- (void)dataTaskWithRequest:(WCSRequest *)request
          completionHandler:(WCSNetworkingCompletionHandlerBlock)completionHandler {
  WCSNetworkingRequest *internalRequest = request.internalRequest;
  [internalRequest assignProperties:self.configuration];
  
  WCSURLSessionManagerDelegate *delegate = [WCSURLSessionManagerDelegate new];
  delegate.dataTaskCompletionHandler = completionHandler;
  delegate.request = request;
  delegate.shouldWriteDirectly = NO;
  
  [self taskWithDelegate:delegate];
}

- (void)taskWithDelegate:(WCSURLSessionManagerDelegate *)delegate {
  if (delegate.downloadingFileURL) delegate.shouldWriteToFile = YES;
  delegate.responseData = nil;
  delegate.responseObject = nil;
  delegate.error = nil;
  WCSNetworkingRequest *internalRequest = delegate.request.internalRequest;
  
  [[[[[WCSTask taskWithResult:nil] continueWithSuccessBlock:^id(WCSTask *task) {
    return [delegate.request constructSessionTaskUsingSession:self.session baseURL:internalRequest.baseURL];
  }] continueWithSuccessBlock:^id _Nullable(WCSTask * _Nonnull task) {
    WCSNetworkingRequest *request = delegate.request.internalRequest;
    if (request.isCancelled) {
      NSError *canceledError;
      if (delegate.dataTaskCompletionHandler) {
        WCSNetworkingCompletionHandlerBlock completionHandler = delegate.dataTaskCompletionHandler;
        canceledError = [NSError errorWithDomain:NSURLErrorDomain
                                            code:NSURLErrorCancelled
                                        userInfo:nil];
        completionHandler(nil, canceledError);
        return [WCSTask taskWithError:canceledError];
      }
//      return [WCSTask taskWithError:canceledError];
    }
    
    return task;
  }] continueWithSuccessBlock:^id(WCSTask *task) {
    internalRequest.task = task.result;
    
    if (internalRequest.task) {
      [self.sessionManagerDelegates setObject:delegate
                                       forKey:@(((NSURLSessionTask *)internalRequest.task).taskIdentifier)];
      [internalRequest.task resume];
    } else {
      WCSLogError(@"Invalid WCSURLSessionTaskType.");
      return [WCSTask taskWithError:[NSError errorWithDomain:WCSNetworkingErrorDomain
                                                        code:WCSNetworkingErrorUnknown
                                                    userInfo:@{NSLocalizedDescriptionKey: @"Invalid WCSURLSessionTaskType."}]];
    }
    
    return nil;
  }] continueWithBlock:^id(WCSTask *task) {
    if (task.error) {
      if (delegate.dataTaskCompletionHandler) {
        WCSNetworkingCompletionHandlerBlock completionHandler = delegate.dataTaskCompletionHandler;
        completionHandler(nil, task.error);
      }
    }
    return nil;
  }];
}

#pragma mark - NSURLSessionTaskDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)sessionTask didCompleteWithError:(NSError *)error {
  if (error) {
    WCSLogError(@"Session task failed with error: %@", error);
  }
  
  [[[WCSTask taskWithResult:nil] continueWithSuccessBlock:^id(WCSTask *task) {
    WCSURLSessionManagerDelegate *delegate = [self.sessionManagerDelegates objectForKey:@(sessionTask.taskIdentifier)];
    
    if (delegate.responseFilehandle) {
      [delegate.responseFilehandle closeFile];
    }
    
    if (!delegate.error) {
      delegate.error = error;
    }
    
    WCSNetworkingRequest *internalRequest = delegate.request.internalRequest;
    
    //delete temporary file if the task contains error (e.g. has been canceled)
    if (error && delegate.tempDownloadedFileURL) {
      [[NSFileManager defaultManager] removeItemAtPath:delegate.tempDownloadedFileURL.path error:nil];
    }
    
    if (!delegate.error
        && [sessionTask.response isKindOfClass:[NSHTTPURLResponse class]]) {
      NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)sessionTask.response;
      
      // TODO:Background task.
      if (delegate.shouldWriteToFile) {
        NSError *error = nil;
        //move the downloaded file to user specified location if tempDownloadFileURL and downloadFileURL are different.
        if (delegate.tempDownloadedFileURL && delegate.downloadingFileURL && [delegate.tempDownloadedFileURL isEqual:delegate.downloadingFileURL] == NO) {
          
          if ([[NSFileManager defaultManager] fileExistsAtPath:delegate.downloadingFileURL.path]) {
            WCSLogWarn(@"Warning: target file already exists, will be overwritten at the file path: %@",delegate.downloadingFileURL);
            [[NSFileManager defaultManager] removeItemAtPath:delegate.downloadingFileURL.path error:&error];
          }
          if (error) {
            WCSLogError(@"Delete File Error: [%@]",error);
          }
          error = nil;
          [[NSFileManager defaultManager] moveItemAtURL:delegate.tempDownloadedFileURL
                                                  toURL:delegate.downloadingFileURL
                                                  error:&error];
        }
        if (error) {
          delegate.error = error;
        } else {
          // FIXME: PARSE RESULT
          //if ([delegate.request.responseSerializer respondsToSelector:@selector(responseObjectForResponse:originalRequest:currentRequest:data:error:)]) {
          //    NSError *error = nil;
          //    delegate.responseObject = [delegate.request.responseSerializer responseObjectForResponse:httpResponse
          //                                                                             originalRequest:sessionTask.originalRequest
          //                                                                              currentRequest:sessionTask.currentRequest
          //                                                                                        data:delegate.downloadingFileURL
          //                                                                                       error:&error];
          //    if (error) {
          //        delegate.error = error;
          //    }
          //}
          //else {
          //    delegate.responseObject = delegate.downloadingFileURL;
          //}
        }
      } else if (!delegate.error) {
        // need to call responseSerializer if there is no client-side error.
        WCSNetworkingRequest *internalRequest = delegate.request.internalRequest;
        if (internalRequest.ouptutClass && [internalRequest.ouptutClass instancesRespondToSelector:@selector(initWithResponseData:HTTPResponse:error:)]) {
          NSError *parseDataError;
          id responseObject = [[internalRequest.ouptutClass alloc] initWithResponseData:delegate.responseData HTTPResponse:httpResponse error:&parseDataError];
          if (parseDataError) {
            delegate.error = parseDataError;
          } else {
            delegate.responseObject = responseObject;
          }
        } else {
          delegate.responseObject = delegate.responseData;
        }
        NSUInteger realExpectedToSend = sessionTask.originalRequest.HTTPBody.length;
        WCSLogVerbose("count of bytes sent %lld, count of bytes expected to send %lld, real expected to send %tu", sessionTask.countOfBytesSent, sessionTask.countOfBytesExpectedToSend, realExpectedToSend);
        WCSNetworkingUploadProgressBlock uploadProgress = delegate.request.internalRequest.uploadProgress;
        // iOS8中可能出现上传进度无法更新的问题，根据countOfBytesExpectedToSend、countOfBytesSent等进行修复。
        BOOL incorrectProgress = realExpectedToSend != sessionTask.countOfBytesExpectedToSend;
        if (!incorrectProgress) {
          incorrectProgress = (sessionTask.countOfBytesExpectedToSend != sessionTask.countOfBytesSent &&
                                    sessionTask.countOfBytesSent > 0 &&
                                    sessionTask.countOfBytesExpectedToSend > 0 );
        }
        if (uploadProgress && incorrectProgress) {
          uploadProgress(realExpectedToSend - sessionTask.countOfBytesSent, realExpectedToSend, realExpectedToSend);
        }
      }
    }
    
    if (delegate.error
        && ([sessionTask.response isKindOfClass:[NSHTTPURLResponse class]] || sessionTask.response == nil)
        && internalRequest.retryHandler) {
      WCSNetworkingRetryType retryType = [internalRequest.retryHandler shouldRetry:delegate.currentRetryCount
                                                                           response:(NSHTTPURLResponse *)sessionTask.response
                                                                    responseObject:delegate.responseObject
                                                                              error:delegate.error];
      switch (retryType) {
        case WCSNetworkingRetryTypeShouldRetry: {
          if ([internalRequest.retryHandler respondsToSelector:@selector(timeIntervalForRetry:response:data:error:)]) {
            NSTimeInterval timeIntervalToSleep = [internalRequest.retryHandler timeIntervalForRetry:delegate.currentRetryCount
                                                                                           response:(NSHTTPURLResponse *)sessionTask.response
                                                                                               data:delegate.responseData
                                                                                              error:delegate.error];
            [NSThread sleepForTimeInterval:timeIntervalToSleep];
          }
          if (internalRequest.decreaseBlock && sessionTask.countOfBytesSent > 0) {
            internalRequest.decreaseBlock(sessionTask.countOfBytesSent);
          }
          delegate.currentRetryCount++;
          [self taskWithDelegate:delegate];
        }
          break;
          
        case WCSNetworkingRetryTypeShouldNotRetry: {
          if (delegate.dataTaskCompletionHandler) {
            WCSNetworkingCompletionHandlerBlock completionHandler = delegate.dataTaskCompletionHandler;
            completionHandler(delegate.responseObject, delegate.error);
          }
        }
          break;
          
        default:
          WCSLogError(@"Unknown retry type. This should not happen.");
          break;
      }
    } else {
      if (delegate.dataTaskCompletionHandler) {
        WCSNetworkingCompletionHandlerBlock completionHandler = delegate.dataTaskCompletionHandler;
        completionHandler(delegate.responseObject, delegate.error);
      }
    }
    return nil;
  }] continueWithBlock:^id(WCSTask *task) {
    [self.sessionManagerDelegates removeObjectForKey:@(sessionTask.taskIdentifier)];
    return nil;
  }];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend {
  WCSLogVerbose("total bytes sent (%lld, %lld)", totalBytesSent, totalBytesExpectedToSend);
  WCSURLSessionManagerDelegate *delegate = [self.sessionManagerDelegates objectForKey:@(task.taskIdentifier)];
  WCSNetworkingUploadProgressBlock uploadProgress = delegate.request.internalRequest.uploadProgress;
  if (uploadProgress) {
    uploadProgress(bytesSent, totalBytesSent, totalBytesExpectedToSend);
  } else {
    WCSLogVerbose("Upload progress not found (%@/%@/%@/%@)", delegate, delegate.request, delegate.request.internalRequest, delegate.request.internalRequest.uploadProgress);
  }
}

#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
  WCSURLSessionManagerDelegate *delegate = [self.sessionManagerDelegates objectForKey:@(dataTask.taskIdentifier)];
  
  //If the response code is not 2xx, avoid write data to disk
  if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    if (httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 ) {
      // status is good, we can keep value of shouldWriteToFile
    } else {
      // got error status code, avoid write data to disk
      delegate.shouldWriteToFile = NO;
    }
  }
  if (delegate.shouldWriteToFile) {
    
    if (delegate.shouldWriteDirectly) {
      WCSLogDebug(@"DirectWrite is On, downloaded data will be wrote to the downloadingFileURL directly, if the file already exists, it will appended to the end.\
                  Original file may be modified even the downloading task has been paused/cancelled later.");
      
      NSError *error = nil;
      if ([[NSFileManager defaultManager] fileExistsAtPath:delegate.downloadingFileURL.path]) {
        WCSLogDebug(@"target file already exists, will be appended at the file path: %@",delegate.downloadingFileURL);
        delegate.responseFilehandle = [NSFileHandle fileHandleForUpdatingURL:delegate.downloadingFileURL error:&error];
        if (error) {
          WCSLogError(@"Error: [%@]", error);
        }
        [delegate.responseFilehandle seekToEndOfFile];
        
      } else {
        //Create the file
        if (![[NSFileManager defaultManager] createFileAtPath:delegate.downloadingFileURL.path contents:nil attributes:nil]) {
          WCSLogError(@"Error: Can not create file with file path:%@",delegate.downloadingFileURL.path);
        }
        error = nil;
        delegate.responseFilehandle = [NSFileHandle fileHandleForWritingToURL:delegate.downloadingFileURL error:&error];
        if (error) {
          WCSLogError(@"Error: [%@]", error);
        }
      }
      
    } else {
      NSError *error = nil;
      //This is the normal case. downloaded data will be saved in a temporay folder and then moved to downloadingFileURL after downloading complete.
      NSString *tempFileName = [NSString stringWithFormat:@"%@.%@",WCSMobileURLSessionManagerCacheDomain,[[NSProcessInfo processInfo] globallyUniqueString]];
      NSString *tempDirPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.fileCache",WCSMobileURLSessionManagerCacheDomain]];
      
      //Create temp folder if not exist
      [[NSFileManager defaultManager] createDirectoryAtPath:tempDirPath withIntermediateDirectories:NO attributes:nil error:nil];
      
      delegate.tempDownloadedFileURL  = [NSURL fileURLWithPath:[tempDirPath stringByAppendingPathComponent:tempFileName]];
      
      //Remove temp file if it has already exists
      if ([[NSFileManager defaultManager] fileExistsAtPath:delegate.tempDownloadedFileURL.path]) {
        WCSLogWarn(@"Warning: target file already exists, will be overwritten at the file path: %@",delegate.tempDownloadedFileURL);
        [[NSFileManager defaultManager] removeItemAtPath:delegate.tempDownloadedFileURL.path error:&error];
      }
      if (error) {
        WCSLogError(@"Error: [%@]", error);
      }
      
      //Create new temp file
      if (![[NSFileManager defaultManager] createFileAtPath:delegate.tempDownloadedFileURL.path contents:nil attributes:nil]) {
        WCSLogError(@"Error: Can not create file with file path:%@",delegate.tempDownloadedFileURL.path);
      }
      error = nil;
      delegate.responseFilehandle = [NSFileHandle fileHandleForWritingToURL:delegate.tempDownloadedFileURL error:&error];
      if (error) {
        WCSLogError(@"Error: [%@]", error);
      }
    }
    
  }
  
  //    if([response isKindOfClass:[NSHTTPURLResponse class]]) {
  //        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
  //        if ([[[httpResponse allHeaderFields] objectForKey:@"Content-Length"] longLongValue] >= WCSMinimumDownloadTaskSize) {
  //            completionHandler(NSURLSessionResponseBecomeDownload);
  //            return;
  //        }
  //    }
  
  completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
  WCSURLSessionManagerDelegate *delegate = [self.sessionManagerDelegates objectForKey:@(dataTask.taskIdentifier)];
  
  if (delegate.responseFilehandle) {
    [delegate.responseFilehandle writeData:data];
  } else {
    if (!delegate.responseData) {
      delegate.responseData = [NSMutableData dataWithData:data];
    } else if ([delegate.responseData isKindOfClass:[NSMutableData class]]) {
      [delegate.responseData appendData:data];
    }
  }
  
  WCSNetworkingDownloadProgressBlock downloadProgress = delegate.request.internalRequest.downloadProgress;
  if (downloadProgress) {
    
    int64_t bytesWritten = [data length];
    delegate.payloadTotalBytesWritten += bytesWritten;
    int64_t byteRangeStartPosition = 0;
    int64_t totalBytesExpectedToWrite = dataTask.response.expectedContentLength;
    if ([dataTask.response isKindOfClass:[NSHTTPURLResponse class]]) {
      NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)dataTask.response;
      NSString *contentRangeString = [[httpResponse allHeaderFields] objectForKey:@"Content-Range"];
      int64_t trueContentLength = [[[contentRangeString componentsSeparatedByString:@"/"] lastObject] longLongValue];
      if (trueContentLength) {
        byteRangeStartPosition = trueContentLength - dataTask.response.expectedContentLength;
        totalBytesExpectedToWrite = trueContentLength;
      }
    }
    downloadProgress(bytesWritten,delegate.payloadTotalBytesWritten + byteRangeStartPosition,totalBytesExpectedToWrite);
  }
}

- (void)URLSession:(NSURLSession *)session
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler
{
  WCSLogDebug(@"didReceiveChallenge");
  //AFNetworking中的处理方式
  NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
  __block NSURLCredential *credential = nil;
  //判断服务器返回的证书是否是服务器信任的
  if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
    credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
    /*disposition：如何处理证书
     NSURLSessionAuthChallengePerformDefaultHandling:默认方式处理
     NSURLSessionAuthChallengeUseCredential：使用指定的证书    
     NSURLSessionAuthChallengeCancelAuthenticationChallenge：取消请求
     */
    if (credential) {
      disposition = NSURLSessionAuthChallengeUseCredential;
    } else {
      disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    }
  } else {
    disposition = NSURLSessionAuthChallengeCancelAuthenticationChallenge;
  }
  //安装证书
  if (completionHandler) {
    completionHandler(disposition, credential);
  }
}

@end
