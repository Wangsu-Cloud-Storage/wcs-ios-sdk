//
//  WCSApi.m
//  WCSiOS
//
//  Created by mato on 16/5/5.
//  Copyright © 2016年 CNC. All rights reserved.
//

#import "WCSApi.h"
#import "WCSClient.h"

@interface WCSRequestWrapper : NSObject

@property (nonatomic, strong) WCSRequest *request;
@property (nonatomic, assign) NSInteger tag;

- (instancetype)initWithRequest:(WCSRequest *)request tag:(NSInteger)tag;

@end

static NSURL *kWCSUploadURL;

@implementation WCSRequestWrapper

- (instancetype)initWithRequest:(WCSRequest *)request tag:(NSInteger)tag {
  if (self = [super init]) {
    _request = request;
    _tag = tag;
  }
  return self;
}

@end

@implementation WCSApi

+ (WCSClient *)sharedClient {
  static dispatch_once_t onceToken;
  static WCSClient *sClient;
  dispatch_once(&onceToken, ^{
    NSURL *baseURL = kWCSUploadURL ? kWCSUploadURL : [NSURL URLWithString:WCSBaseUploadString];
    sClient = [[WCSClient alloc] initWithBaseURL:baseURL andTimeout:30];
  });
  return sClient;
}

+ (void)configUploadUrl:(NSString*)uploadUrl {
  if(uploadUrl && uploadUrl.length > 0){
    kWCSUploadURL = [NSURL URLWithString:uploadUrl];
  } else {
    WCSLogError("url invalidate");
  }

  if(![kWCSUploadURL.absoluteString isEqualToString:[[self class] sharedClient].baseURL.absoluteString]){
    WCSLogError("config upload url failed, Please call configUploadUrl first before you upload files.");
  }
}

+ (void)cancelUploadingOperationInTag:(NSUInteger)tag {
  @synchronized (self) {
    NSMutableSet *completedRequests = [NSMutableSet set];
    [[self runningSet] enumerateObjectsUsingBlock:^(WCSRequestWrapper *obj, BOOL * _Nonnull stop) {
      if (obj.tag == tag) {
        [obj.request cancel];
        [completedRequests addObject:obj];
      }
    }];
    [[self runningSet] minusSet:completedRequests];
  }
}

+ (void)uploadFileWithUploadToken:(NSString*)uploadToken
                         fileData:(NSData*)fileData
                        fileNamed:(NSString*)fileName
                     fileMimeType:(NSString*)mimeType
                          taskTag:(NSUInteger)taskTag
                     callbackBody:(NSDictionary*)callbackBody
                usingSuccessBlock:(void(^)(NSInteger statusCode, NSDictionary *response))successBlock
                    progressBlock:(void(^)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))progressBlock
                    failuredBlock:(void(^)(NSInteger statusCode, NSDictionary *errorMsg))failuredBlock {
  WCSUploadObjectRequest *uploadRequest = [[WCSUploadObjectRequest alloc] init];
  uploadRequest.fileData = fileData;
  uploadRequest.fileName = fileName;
  uploadRequest.token = uploadToken;
  uploadRequest.mimeType = mimeType;
  uploadRequest.customParams = callbackBody;
  [uploadRequest setUploadProgress:^(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend) {
    if (progressBlock) {
      progressBlock(bytesSent, totalBytesSent, totalBytesExpectedToSend);
    }
  }];
  if (taskTag > 0) {
    [self addRunningRequest:uploadRequest taged:taskTag];
  }
  
  [[[[self class] sharedClient] uploadRequest:uploadRequest] continueWithExecutor:[WCSExecutor mainThreadExecutor] withBlock:^id _Nullable(WCSTask<WCSUploadObjectResult *> * _Nonnull task) {
    [WCSApi removeRunningRequest:uploadRequest];
    if (task.isFaulted) {
      NSInteger errorCode = task.error.code;
      NSString *errorMessage = [task.error.userInfo safeStringForKey:WCSErrorKey];
      if (failuredBlock) {
        failuredBlock(errorCode, @{@"code" : @(errorCode), @"message" : errorMessage});
      }
    } else {
      if (successBlock) {
        successBlock(200, task.result.results);
      }
    }
    return nil;
  }];
}

+ (void)sliceUploadFile:(NSString*)filePath
                  token:(NSString*)uploadToken
                taskTag:(NSUInteger)taskTag
           callbackBody:(NSDictionary*)callbackBody
          progressBlock:(void(^)(long long totalBytesWritten, long long totalBytesExpectedToWrite))progressBlock
           successBlock:(void(^)(NSDictionary *responseDict))successBlock
          failuredBlock:(void(^)(NSDictionary* errorMsg))failuredBlock {
  WCSBlockUploadRequest *request = [[WCSBlockUploadRequest alloc] init];
  request.fileURL = [NSURL URLWithString:filePath];
  request.uploadToken = uploadToken;
  request.customParams = callbackBody;
  [request setUploadProgress:^(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend) {
    progressBlock(totalBytesSent, totalBytesExpectedToSend);
  }];
  if (taskTag > 0) {
    [[self class] addRunningRequest:request taged:taskTag];
  }
  
  [[[[self class] sharedClient] blockUploadRequest:request] continueWithBlock:^id _Nullable(WCSTask<WCSBlockUploadResult *> * _Nonnull task) {
    [WCSApi removeRunningRequest:request];
    if (task.isFaulted) {
      NSInteger errorCode = task.error.code;
      NSString *errorMessage = [task.error.userInfo safeStringForKey:WCSErrorKey];
      if (failuredBlock) {
        failuredBlock(@{@"code" : @(errorCode), @"message" : errorMessage});
      }
    } else {
      if (successBlock) {
        successBlock(task.result.results);
      }
    }
    return nil;
  }];
}

+ (void)addRunningRequest:(WCSRequest *)request taged:(NSInteger)tag {
  @synchronized (self) {
    WCSRequestWrapper *requestWrapper = [[WCSRequestWrapper alloc] initWithRequest:request tag:tag];
    [[self runningSet] addObject:requestWrapper];
  }
}

+ (void)removeRunningRequest:(WCSRequest *)request {
  @synchronized (self) {
    NSMutableSet *completedRequests = [NSMutableSet set];
    [[self runningSet] enumerateObjectsUsingBlock:^(WCSRequestWrapper *obj, BOOL * _Nonnull stop) {
      if (obj.request == request) {
        [completedRequests addObject:obj];
      }
    }];
    [[self runningSet] minusSet:completedRequests];
  }
}

+ (NSMutableSet *)runningSet {
  static dispatch_once_t onceToken;
  static NSMutableSet *sRunningRequest;
  dispatch_once(&onceToken, ^{
    sRunningRequest = [NSMutableSet set];
  });
  return sRunningRequest;
}

@end
