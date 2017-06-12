//
//  WCSClient.m
//  WCSiOS
//
//  Created by mato on 16/3/24.
//  Copyright © 2016年 CNC. All rights reserved.
//

#import "WCSDefines.h"
#import "WCSClient.h"
#import "WCSNetworking.h"
#import "WCSBolts.h"
#import "WCSBlock.h"
#import "WCSMakeBlockRequest.h"
#import "WCSMakeBlockResult.h"
#import "WCSUploadChunkRequest.h"
#import "WCSUploadChunkResult.h"
#import "WCSCommonAlgorithm.h"
#import "WCSChunkCache.h"
#import "WCSChunkCacheManager.h"
#import "WCSThreadSafeMutableDictionary.h"
#import "WCSGTMStringEncoding.h"
#import "WCSTimeoutRetryHandler.h"
#include "dns_sd.h"

#if  __IPHONE_OS_VERSION_MIN_REQUIRED != __IPHONE_7_0
#error wrong deployment target - should be 7.0
#endif

NSString * const WCSiOSSDKVersion = WCS_IOS_VERSION;

static NSString * const kWCSTaskMakeBlockKey = @"kWCSTaskMakeBlockKey";
static NSString * const kWCSTaskBlockKey = @"kWCSTaskBlockKey";
static NSUInteger const kDefaultConcurrentCount = 5;
static NSUInteger const kDefaultTimeout = 30;
static NSUInteger const kDefaultRetryTimes = 3;

@interface WCSRequest()

@property (nonatomic, strong) WCSNetworkingRequest *internalRequest;

@end

@interface WCSClient()

@property (nonatomic, strong) WCSNetworking *networking;
// 主要用于控制块的并发数，最终实际的并发数主要取决于NSURLSession。（底层的并发数经测试基本大于10个线程。）
@property (nonatomic, strong) NSOperationQueue *operationQueue;

@end

@interface WCSClient(WCSApiCompatible)

@end

@interface WCSChunkProgressNotifier : NSObject

- (instancetype)initWithTotal:(int64_t)total progressBlock:(void(^)(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend))progressBlock;

- (void)increaseByWritten:(int64_t)written;

- (void)decreaseByReverted:(int64_t)reverted;

@end


@interface WCSBlockUploadRequest()

@property (atomic, strong) WCSThreadSafeMutableDictionary *pendingRequestDict;// of WCSRequest
@property (nonatomic, copy) NSArray *contextList;
@property (nonatomic, copy) WCSNetworkingUploadProgressBlock uploadProgressBlock;
@property (nonatomic, strong) WCSChunkProgressNotifier *progressNotifier;
@property (nonatomic, copy) NSString *uploadBatch;

@end

@implementation WCSClient

- (instancetype)initWithBaseURL:(NSURL *)baseURL {
  return [self initWithBaseURL:baseURL andTimeout:kDefaultTimeout concurrentCount:kDefaultConcurrentCount retryTimes:kDefaultRetryTimes proxyDictionary:nil];
}

- (instancetype)initWithBaseURL:(NSURL *)baseURL andTimeout:(NSTimeInterval)timeout {
  return [self initWithBaseURL:baseURL andTimeout:timeout concurrentCount:kDefaultConcurrentCount retryTimes:kDefaultRetryTimes proxyDictionary:nil];
}

- (instancetype)initWithBaseURL:(NSURL *)baseURL
                     andTimeout:(NSTimeInterval)timeout
                concurrentCount:(NSUInteger)concurrentCount {
  return [self initWithBaseURL:baseURL andTimeout:timeout concurrentCount:kDefaultConcurrentCount retryTimes:kDefaultRetryTimes proxyDictionary:nil];
}

- (instancetype)initWithBaseURL:(NSURL *)baseURL andTimeout:(NSTimeInterval)timeout proxyDictionary:(NSDictionary *)proxyDictionary{
  return [self initWithBaseURL:baseURL andTimeout:timeout concurrentCount:kDefaultConcurrentCount retryTimes:kDefaultRetryTimes proxyDictionary:proxyDictionary];
}
- (instancetype)initWithBaseURL:(NSURL *)baseURL
                     andTimeout:(NSTimeInterval)timeout
                concurrentCount:(NSUInteger)concurrentCount
                     retryTimes:(NSUInteger)retryTimes{
  return [self initWithBaseURL:baseURL andTimeout:timeout concurrentCount:concurrentCount retryTimes:retryTimes proxyDictionary:nil];
}

- (instancetype)initWithBaseURL:(NSURL *)baseURL
                     andTimeout:(NSTimeInterval)timeout
                concurrentCount:(NSUInteger)concurrentCount
                     retryTimes:(NSUInteger)retryTimes
                proxyDictionary:(NSDictionary *)proxyDictionary
{
  if (self = [super init]) {
    WCSNetworkingConfiguration *networkConfig = [[WCSNetworkingConfiguration alloc] init];
    NSTimeInterval realTimeout = kDefaultTimeout;
    if (timeout > 0) {
      realTimeout = timeout;
    }
    networkConfig.timeoutIntervalForRequest = realTimeout;
    networkConfig.baseURL = baseURL;
    networkConfig.proxyDictionary = proxyDictionary;

    NSUInteger realRetryTimes = kDefaultRetryTimes;
    if (retryTimes > 0) {
      realRetryTimes = retryTimes;
    }
    networkConfig.retryHandler = [[WCSTimeoutRetryHandler alloc] initWithRetryTimes:realRetryTimes];
    _baseURL = [baseURL copy];
    _timeout = realTimeout;
    _networking = [[WCSNetworking alloc] initWithConfiguration:networkConfig];
    _operationQueue = [[NSOperationQueue alloc] init];
    if (concurrentCount == 0 || concurrentCount > 10) {
      _operationQueue.maxConcurrentOperationCount = kDefaultConcurrentCount;
    } else {
      _operationQueue.maxConcurrentOperationCount = concurrentCount;
    }
  }
  return self;
}

- (WCSTask<WCSUploadObjectResult *> *)uploadRequest:(WCSUploadObjectRequest *)request {
  return [self invokeRequest:request outputClass:[WCSUploadObjectResult class]];
}

- (WCSTask<WCSUploadObjectStringResult *> * _Nonnull)uploadRequestRaw:(WCSUploadObjectRequest * _Nonnull)request {
  return [self invokeRequest:request outputClass:[WCSUploadObjectStringResult class]];
}

- (WCSTask<WCSBlockUploadBase64Result *> * _Nonnull)blockUploadRequestRaw:(WCSBlockUploadRequest * _Nonnull)blockRequest {
  return [[self blockUploadRequest:blockRequest] continueWithSuccessBlock:^id _Nullable(WCSTask<WCSBlockUploadResult *> * _Nonnull task) {
    return [WCSTask taskWithResult:[[WCSBlockUploadBase64Result alloc] initWithJSONDiction:task.result.results]];
  }];
}

- (WCSTask<WCSBlockUploadResult *> *)blockUploadRequest:(WCSBlockUploadRequest *)blockRequest {
  NSError *error = [blockRequest validateRequest];
  if (error) {
    WCSLogError("request of WCSBlockUploadRequest invalidate %@", error);
    return [WCSTask taskWithError:error];
  }
  
  NSArray *blocks = [WCSBlock blocksFromFilePath:blockRequest.fileURL.absoluteString
                                       blockSize:blockRequest.blockSize
                                       chunkSize:blockRequest.chunkSize];
  if (blocks.count == 0) {
    WCSLogError("read file failed with error %@", error);
    return [WCSTask taskWithError:[NSError errorWithDomain:WCSClientErrorDomain code:WCSClientErrorInvalidateParameter userInfo:@{WCSErrorKey : @"Read file failed."}]];
  }
  
  return [[[WCSTask taskWithResult:nil] continueWithSuccessBlock:^id _Nullable(WCSTask * _Nonnull task) {
    WCSLogDebug("computeing file md5.");
    return [self computeFileMD5String:blockRequest.fileURL.absoluteString];
  }] continueWithSuccessBlock:^id _Nullable(WCSTask * _Nonnull task) {
    // Restore upload history
    WCSBlock *firstBlock = blocks[0];
    UInt64 fileSize = firstBlock.fileSize;
    if (blockRequest.uploadProgressBlock) {
      blockRequest.progressNotifier = [[WCSChunkProgressNotifier alloc] initWithTotal:fileSize progressBlock:blockRequest.uploadProgressBlock];
    }
    NSString *fileMD5 = task.result;
    WCSChunkCache *chunkCache = [WCSChunkCache chunkCacheFromFileMD5:fileMD5 token:blockRequest.uploadToken fileKey:blockRequest.fileKey blockArray:blocks];
    [[WCSChunkCacheManager sharedInstance] addChunkCache:chunkCache];
    WCSLogDebug("Chunk cache found %@", chunkCache);
    UInt64 uploadedSize = [chunkCache uploadedSizeInBlockArray:blocks];
    uploadedSize = uploadedSize > fileSize ? fileSize : uploadedSize;
    [blockRequest.progressNotifier increaseByWritten:uploadedSize];
    blockRequest.uploadBatch = chunkCache.uploadBatch;
    
    if (uploadedSize >= fileSize) {
      blockRequest.contextList = chunkCache.blockContextArray;
      return [self invokeRequest:blockRequest outputClass:[WCSBlockUploadResult class]];
    }
    
    NSMutableArray *tasks = [NSMutableArray array];
    
    for (int i = 0; i < blocks.count; i++) {
      WCSTask *asyncTask = [self uploadBlockAsync:blocks[i] chunkCache:chunkCache blockRequest:blockRequest];
      [tasks addObject:asyncTask];
    }
    
    return [self sureReusltAndMakeFileUsingRequest:blockRequest tasks:tasks chunkCache:chunkCache];
  }];
}

- (WCSTask *)uploadBlockAsync:(WCSBlock *)currentBlock chunkCache:(WCSChunkCache *)chunkCache blockRequest:(WCSBlockUploadRequest *)blockRequest {
  WCSTaskCompletionSource *completeTask = [WCSTaskCompletionSource taskCompletionSource];
  [self.operationQueue addOperationWithBlock:^{
    WCSLogVerbose("block operation queue executed while block %@ cancelled.", blockRequest.cancelled ? @"was" : @"not");
    WCSLogDebug("Upload block %zd started.", currentBlock.blockIndex);
    if (!blockRequest.cancelled) {
      WCSTask *uploadBlockTask = [self uploadBlock:currentBlock chunkCache:chunkCache blockRequest:blockRequest];
      if (uploadBlockTask.cancelled) {
        [completeTask setError:[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:nil]];
      } else if (uploadBlockTask.faulted) {
        [completeTask setError:uploadBlockTask.error];
      } else {
        [completeTask setResult:uploadBlockTask.result];
      }
    } else {
      [completeTask setError:[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:nil]];
    }
    WCSLogDebug("Upload block %zd completed.", currentBlock.blockIndex);
  }];
  return completeTask.task;
}

- (WCSTask *)uploadBlock:(WCSBlock *)currentBlock chunkCache:(WCSChunkCache *)chunkCache blockRequest:(WCSBlockUploadRequest *)blockRequest {
  return [[WCSTask taskWithResult:nil] continueWithBlock:^id _Nullable(WCSTask * _Nonnull task) {
    // Make block directly while upload history not found
    if (currentBlock.currentChunkIndex == 0) {
      NSData *chunkData = [currentBlock moveToNextChunk];
      WCSMakeBlockRequest *makeBlockRequest = {
        [[WCSMakeBlockRequest alloc] initWithUploadToken:blockRequest.uploadToken
                                                    size:chunkData.length
                                                   order:currentBlock.blockIndex
                                               blockSize:currentBlock.size
                                             chunkedData:chunkData
                                                 fileKey:blockRequest.fileKey
                                                mimeType:blockRequest.mimeType
                                             uploadBatch:blockRequest.uploadBatch]
      };
      WCSLogVerbose("append pending request %@", makeBlockRequest);
      [blockRequest.pendingRequestDict setObject:makeBlockRequest forKey:@([currentBlock hash])];
      
      [makeBlockRequest setUploadProgress:^(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend) {
        WCSLogVerbose("make bytes sent %lld", totalBytesSent);
        [blockRequest.progressNotifier increaseByWritten:bytesSent];
      }];
      
      [makeBlockRequest setDecreaseProgress:^(int64_t bytesReverted) {
        WCSLogVerbose("decrease process %lld", bytesReverted);
        [blockRequest.progressNotifier decreaseByReverted:bytesReverted];
      }];
      
      WCSTask *makeBlockTask = [[self invokeRequest:makeBlockRequest outputClass:[WCSMakeBlockResult class]] continueWithSuccessBlock:^id _Nullable(WCSTask * _Nonnull task) {
        // upload second chunk
        [blockRequest.pendingRequestDict removeObjectForKey:@([currentBlock hash])];
        WCSMakeBlockResult *makeBlockResult = task.result;
        
        // update cache
        [chunkCache setContext:makeBlockResult.context uploadedIndex:currentBlock.currentChunkIndex atBlockIndex:currentBlock.blockIndex];
        
        WCSUploadChunkResult *uploadChunkResult = [[WCSUploadChunkResult alloc] init];
        uploadChunkResult.crc32 = makeBlockResult.crc32;
        uploadChunkResult.offset = makeBlockResult.offset;
        uploadChunkResult.checksum = makeBlockResult.checksum;
        uploadChunkResult.context = makeBlockResult.context;
        WCSLogVerbose("block request %@ cancelled", blockRequest.cancelled ? @"was" : @"not");
        return [WCSTask taskWithResult:uploadChunkResult];
      }];
      [makeBlockTask waitUntilFinished];
      if (makeBlockTask.cancelled || makeBlockTask.error) {
        [blockRequest cancel];
        return makeBlockTask;
      }
      
      WCSTask *uploadChunksTask = [self uploadChunkInBlock:currentBlock
                                               withRequest:blockRequest
                                                    result:makeBlockTask.result
                                                chunkCache:chunkCache
                                              atBlockIndex:currentBlock.blockIndex];
      if (uploadChunksTask.cancelled || uploadChunksTask.faulted) {
        [blockRequest cancel];
      }
      
      return uploadChunksTask;
    } else {
      WCSUploadChunkResult *chunkResult = [[WCSUploadChunkResult alloc] init];
      chunkResult.offset = currentBlock.currentChunkIndex * currentBlock.chunkSize;
      chunkResult.context = [chunkCache.blockContextArray objectAtIndex:currentBlock.blockIndex];
      WCSTask *uploadChunksTask = [self uploadChunkInBlock:currentBlock
                                               withRequest:blockRequest
                                                    result:chunkResult
                                                chunkCache:chunkCache
                                              atBlockIndex:currentBlock.blockIndex];
      if (uploadChunksTask.cancelled || uploadChunksTask.error) {
        [blockRequest cancel];
      }
      return uploadChunksTask;
    }
  }];
}

- (WCSTask *)uploadChunkInBlock:(WCSBlock *)block
                    withRequest:(WCSBlockUploadRequest *)blockUploadRequest
                         result:(WCSUploadChunkResult *)uploadChunkResult
                     chunkCache:(WCSChunkCache *)chunkCache
                   atBlockIndex:(NSUInteger)blockIndex {
  WCSLogVerbose("block request %@ cancelled", blockUploadRequest.cancelled ? @"was" : @"not");
  WCSTask *task = nil;
  @autoreleasepool {
    [chunkCache setContext:uploadChunkResult.context uploadedIndex:block.currentChunkIndex atBlockIndex:blockIndex];
    NSData *nextChunkData = [block moveToNextChunk];
    if (nextChunkData) {
      WCSUploadChunkRequest *uploadChunkRequest = {
        [[WCSUploadChunkRequest alloc] initWithOffset:uploadChunkResult.offset
                                          lastContext:uploadChunkResult.context
                                          uploadToken:blockUploadRequest.uploadToken
                                          chunkedData:nextChunkData
                                              fileKey:blockUploadRequest.fileKey
                                             mimeType:blockUploadRequest.mimeType
                                          uploadBatch:blockUploadRequest.uploadBatch]
      };
      [blockUploadRequest.pendingRequestDict setObject:uploadChunkRequest forKey:@([block hash])];
      
      [uploadChunkRequest setUploadProgress:^(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend) {
        WCSLogVerbose("uploading chunk request sent bytes %lld", totalBytesSent);
        [blockUploadRequest.progressNotifier increaseByWritten:bytesSent];
      }];
      
      [uploadChunkRequest setDecreaseProgress:^(int64_t bytesReverted) {
        WCSLogVerbose("bytes reverted %lld", bytesReverted);
        [blockUploadRequest.progressNotifier decreaseByReverted:bytesReverted];
      }];
      
      // 如果外部已经取消上传，则结束当前block的上传，需要在设置pendingRequestDict之后执行。
      if (blockUploadRequest.cancelled) {
        [blockUploadRequest.pendingRequestDict removeObjectForKey:@([block hash])];
        return [WCSTask taskWithError:[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:nil]];
      }
      task = [self invokeRequest:uploadChunkRequest outputClass:[WCSUploadChunkResult class]];
      [task waitUntilFinished];
    }
  }
  if (task) {
    if (task.cancelled) {
      return [WCSTask taskWithError:[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:nil]];
    } else if (task.result && [task.result isKindOfClass:[WCSUploadChunkResult class]]) {
      WCSUploadChunkResult *result = task.result;
      return [self uploadChunkInBlock:block
                          withRequest:blockUploadRequest
                               result:result
                           chunkCache:chunkCache
                         atBlockIndex:blockIndex];
    } else {
      return task;
    }
  }
  WCSTask *resultTask = [WCSTask taskWithResult:uploadChunkResult.context];
  return resultTask;
}

- (WCSTask<NSString *> *)computeFileMD5String:(NSString *)fileURLString {
  // compute md5 in background thread.
  NSString *MD5String = [WCSCommonAlgorithm MD5StringFromString:fileURLString];
  if (MD5String && MD5String.length != 0) {
    return [WCSTask taskWithResult:MD5String];
  } else {
    return [WCSTask taskWithError:[NSError errorWithDomain:WCSClientErrorDomain code:WCSClientErrorInvalidateParameter userInfo:@{WCSErrorKey : @"Read file failed."}]];
  }
}

- (WCSTask *)sureReusltAndMakeFileUsingRequest:(WCSBlockUploadRequest *)blockRequest
                                         tasks:(NSArray *)tasks
                                    chunkCache:(WCSChunkCache *)chunkCache {
  return [[WCSTask taskForCompletionOfAllTasks:tasks] continueWithBlock:^id _Nullable(WCSTask * _Nonnull task) {
    [blockRequest.pendingRequestDict removeAllObjects];
    NSMutableArray *contextList = [NSMutableArray arrayWithCapacity:tasks.count];
    NSMutableArray *subErrors = [NSMutableArray arrayWithCapacity:tasks.count];
    NSError *error;
    
    for (WCSTask *contextTask in tasks) {
      if (contextTask.result && [contextTask.result isKindOfClass:[NSString class]]) {
        [contextList addObject:contextTask.result];
      } else if (contextTask.error) {
        [subErrors addObject:contextTask.error];
        if (contextTask.error.code == NSURLErrorCancelled) {
          if ( [[task.error.userInfo objectForKey:@"errors"] count]==0 ) {
            error = [NSError errorWithDomain:contextTask.error.domain code:NSURLErrorCancelled userInfo:@{WCSErrorKey : @"Block upload canceled.", WCSSubErrorsKey : task.error.userInfo}];
          }else{
            error = [NSError errorWithDomain:contextTask.error.domain code:NSURLErrorCancelled userInfo:@{WCSErrorKey : @"Block upload canceled.", WCSSubErrorsKey : [task.error.userInfo objectForKey:@"errors"]}];
          }
        } else {
          error = [NSError errorWithDomain:WCSClientErrorDomain code:WCSClientErrorBlockUploadFailed userInfo:@{WCSErrorKey : @"Upload blocks failed.", WCSSubErrorsKey : subErrors}];
          WCSLogError("sub error %@", contextTask.error);
          break;
        }
      } else if (task.cancelled) {
      } else {
        error = [NSError errorWithDomain:WCSClientErrorDomain code:WCSClientErrorUnknown userInfo:@{WCSErrorKey : @"Unknown error."}];
      }
    }
    if (error) {
      return [WCSTask taskWithError:error];
    }
    blockRequest.contextList = [contextList copy];
    // make file
    return [[self invokeRequest:blockRequest outputClass:[WCSBlockUploadResult class]] continueWithSuccessBlock:^id _Nullable(WCSTask * _Nonnull task) {
      [[WCSChunkCacheManager sharedInstance] removeChunkCache:chunkCache.fileHash];
      return task;
    }];
  }];
}

- (WCSTask *)invokeRequest:(WCSRequest *)request
               outputClass:(Class)outputClass {
  request.internalRequest.ouptutClass = outputClass;
  return [[self.networking sendRequest:request] continueWithBlock:^id(WCSTask *task) {
    request.internalRequest = nil;
    return task;
  }];
}

@end
