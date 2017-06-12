//
//  WCSMakeFileRequest.m
//  WCSiOS
//
//  Created by mato on 16/4/25.
//  Copyright © 2016年 CNC. All rights reserved.
//

#import "WCSBlockUploadRequest.h"
#import "WCSThreadSafeMutableDictionary.h"
#import "WCSBlock.h"
#import <MobileCoreServices/MobileCoreServices.h>

static NSString * WCSContentTypeForPathExtension(NSString *extension) {
  NSString *UTI = (__bridge_transfer NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)extension, NULL);
  NSString *contentType = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)UTI, kUTTagClassMIMEType);
  if (!contentType) {
    return @"application/octet-stream";
  } else {
    return contentType;
  }
}

@interface WCSChunkProgressNotifier : NSObject

@property (nonatomic, copy) void(^progressBlock)(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend);
@property (nonatomic, assign) int64_t written;
@property (nonatomic, assign) int64_t total;
@property (nonatomic, strong) dispatch_semaphore_t lock;

- (instancetype)initWithTotal:(int64_t)total progressBlock:(void(^)(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend))progressBlock;

- (void)increaseByWritten:(int64_t)written;

- (void)decreaseByReverted:(int64_t)reverted;

@end

@implementation WCSChunkProgressNotifier

- (instancetype)initWithTotal:(int64_t)total progressBlock:(void(^)(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend))progressBlock{
  if(self = [super init]){
    _total = total;
    _progressBlock = [progressBlock copy];
    _lock = dispatch_semaphore_create(1);
  }
  return self;
}

- (void)increaseByWritten:(int64_t)written{
  dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
  self.written += written;
  dispatch_semaphore_signal(_lock);
  self.progressBlock(written, self.written, self.total);
}

- (void)decreaseByReverted:(int64_t)reverted {
  dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
  self.written -= reverted;
  dispatch_semaphore_signal(_lock);
  self.progressBlock(-reverted, self.written, self.total);
}

@end

@interface WCSBlockUploadRequest()

@property (atomic, strong) WCSThreadSafeMutableDictionary *pendingRequestDict;
@property (nonatomic, copy) NSArray *contextList;
@property (nonatomic, copy) WCSNetworkingUploadProgressBlock uploadProgressBlock;
@property (nonatomic, strong) WCSChunkProgressNotifier *progressNotifier;
@property (nonatomic, copy) NSString *uploadBatch;

@end

@implementation WCSBlockUploadRequest

- (instancetype)init {
  if (self = [super init]) {
    _pendingRequestDict = [[WCSThreadSafeMutableDictionary alloc] init];
    _blockSize = kWCSDefualtBlockSize;
    _chunkSize = kWCSDefaultChunkSize;
  }
  return self;
}

- (WCSTask *)constructSessionTaskUsingSession:(NSURLSession *)session baseURL:(NSURL *)baseURL {
  return [[WCSTask taskWithResult:nil] continueWithSuccessBlock:^id _Nullable(WCSTask * _Nonnull task) {
    NSError *error = nil;
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[self.fileURL path] error:&error];
    NSMutableString *pathForMakeFile = [NSMutableString stringWithFormat:@"/mkfile/%@", @([fileAttributes fileSize])];
    [self.customParams enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
      NSString *encodedObj = [WCSCommonAlgorithm webSafeBase64EncodedString:obj];
      [pathForMakeFile appendFormat:@"/%@/%@", key, encodedObj];
    }];
    NSString *baseURLString = baseURL != nil ? baseURL.absoluteString : WCSBaseUploadString;
    NSString *URLString = [NSString stringWithFormat:@"%@%@", baseURLString, pathForMakeFile];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:URLString]];
    if (self.fileKey && self.fileKey.length != 0) {
      NSString *encodedFileKey = [WCSCommonAlgorithm webSafeBase64EncodedString:self.fileKey];
      [request setValue:encodedFileKey forHTTPHeaderField:@"key"];
    }
    [request setValue:self.uploadBatch forHTTPHeaderField:@"UploadBatch"];
    [request setValue:self.mimeType forHTTPHeaderField:@"mimeType"];
    request.HTTPMethod = [NSString wcs_stringWithHTTPMethod:WCSHTTPMethodPOST];
    request.HTTPBody = [[self contextListFromArray:self.contextList] dataUsingEncoding:NSUTF8StringEncoding];
    [request setValue:self.uploadToken forHTTPHeaderField:@"Authorization"];
    [request setValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];
    return [WCSTask taskWithResult:[session dataTaskWithRequest:request]];
  }];
}

- (WCSTask *)cancel {
  if (self.pendingRequestDict.count != 0) {
    for (NSString *requestHash in self.pendingRequestDict.allKeys) {
      WCSRequest *request = [self.pendingRequestDict objectForKey:requestHash];
      [request cancel];
      WCSLogVerbose("cancelled request %@", request);
    }
    [self.pendingRequestDict removeAllObjects];
  }
  [super cancel];
  return [WCSTask taskWithResult:nil];
}

- (NSString *)mimeType {
  if (!_mimeType || _mimeType.length == 0) {
    _mimeType = WCSContentTypeForPathExtension([self.fileURL pathExtension]);
  }
  return _mimeType;
}

- (void)setUploadProgress:(void (^)(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend))uploadProgress {
  _uploadProgressBlock = [uploadProgress copy];
}

- (NSError *)validateRequest {
  NSString *errorMessage = nil;
  if (!self.fileURL || ![[NSFileManager defaultManager] fileExistsAtPath:[self.fileURL path]]) {
    errorMessage = @"File not found at fileURL";
  }
  
  if (!errorMessage && (!self.uploadToken || self.uploadToken.length == 0)) {
    errorMessage = @"token needed.";
  }
  
  if (!errorMessage && ((self.blockSize % kWCSMinBlockSize != 0) || (self.blockSize > kWCSMaxBlockSize))) {
    errorMessage = @"Illegal block size.";
  }
  
  if (!errorMessage && ((self.chunkSize % kWCSMinChunkSize != 0) || (self.chunkSize > self.blockSize))) {
    errorMessage = @"Illegal chunk size.";
  }
  
  NSError *error = nil;
  NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[self.fileURL path] error:&error];
  if (!errorMessage && (error || [fileAttributes fileSize] == 0)) {
    errorMessage = @"Read file failed.";
  }
  
  if (errorMessage) {
    return [NSError errorWithDomain:WCSClientErrorDomain
                                         code:WCSClientErrorInvalidateParameter
                                     userInfo:@{WCSErrorKey : errorMessage}];
  }
  return nil;
}

- (NSString*)contextListFromArray:(NSArray*)contextArray {
  NSMutableString* contextListString = [NSMutableString string];
  for (int i = 0; i < contextArray.count; i++) {
    [contextListString appendString:[contextArray objectAtIndex:i]];
    if(i + 1 < contextArray.count){
      [contextListString appendString:@","];
    }
  }
  return [NSString stringWithString:contextListString];
}

- (void)increaseByWritten:(int64_t)written {
  [self.progressNotifier increaseByWritten:written];
}

@end
