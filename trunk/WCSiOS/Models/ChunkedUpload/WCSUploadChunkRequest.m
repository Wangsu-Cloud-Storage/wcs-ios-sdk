//
//  WCSUploadChunkRequest.m
//  WCSiOS
//
//  Created by mato on 16/4/25.
//  Copyright © 2016年 CNC. All rights reserved.
//

#import "WCSUploadChunkRequest.h"
#import "WCSUploadChunkResult.h"
#import "NSData+WCSCommonAlgorithm.h"

@interface WCSUploadChunkRequest()

@property (nonatomic, strong) id<WCSURLRequestRetryHandler> retryHandler;

@end

@implementation WCSUploadChunkRequest

- (instancetype)initWithOffset:(UInt64)offset
                   lastContext:(NSString *)lastContext
                   uploadToken:(NSString *)uploadToken
                   chunkedData:(NSData *)chunkedData
                       fileKey:(NSString *)fileKey
                      mimeType:(NSString *)mimeType
                   uploadBatch:(NSString *)uploadBatch{
  if (self = [super init]) {
    _offset = offset;
    _lastContext = [lastContext copy];
    _uploadToken = [uploadToken copy];
    _chunkedData = chunkedData;
    _fileKey = [fileKey copy];
    _mimeType = [mimeType copy];
    _uploadBatch = [uploadBatch copy];
  }
  return self;
}

- (WCSTask *)constructSessionTaskUsingSession:(NSURLSession *)session baseURL:(NSURL *)baseURL {
  return [[[WCSTask taskWithResult:nil] continueWithSuccessBlock:^id _Nullable(WCSTask * _Nonnull task) {
    return [self validateRequest];
  }] continueWithSuccessBlock:^id _Nullable(WCSTask * _Nonnull task) {
    NSString *pathFormPut = [NSString stringWithFormat:@"/bput/%@/%@", self.lastContext, @(self.offset)];
    NSString *baseURLString = baseURL != nil ? baseURL.absoluteString : WCSBaseUploadString;
    NSString *URLString = [NSString stringWithFormat:@"%@%@", baseURLString, pathFormPut];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:URLString]];
    
    if (self.fileKey && self.fileKey.length != 0) {
      NSString *encodedFileKey = [WCSCommonAlgorithm webSafeBase64EncodedString:self.fileKey];
      [request setValue:encodedFileKey forHTTPHeaderField:@"key"];
    }
    if (self.mimeType && self.mimeType.length != 0) {
      [request setValue:self.mimeType forHTTPHeaderField:@"mimeType"];
    }
    [request setValue:self.uploadBatch forHTTPHeaderField:@"UploadBatch"];
    request.HTTPMethod = [NSString wcs_stringWithHTTPMethod:WCSHTTPMethodPOST];
    request.HTTPBody = self.chunkedData;
    [request setValue:self.uploadToken forHTTPHeaderField:@"Authorization"];
    [request setValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];
    return [WCSTask taskWithResult:[session dataTaskWithRequest:request]];
  }];
}

- (WCSTask *)validateRequest {
  NSString *errorMsg;
  if (!self.uploadToken || self.uploadToken.length == 0) {
    errorMsg = @"Upload Token Needed.";
  }
  
  if (errorMsg && (!self.lastContext || self.lastContext.length == 0)) {
    errorMsg = @"Last context empty.";
  }
  
  if (errorMsg && (!self.chunkedData || self.chunkedData.length == 0)) {
    errorMsg = @"Chunked data not found.";
  }
  
  if (errorMsg) {
    NSError *error = [NSError errorWithDomain:WCSClientErrorDomain
                                         code:WCSClientErrorInvalidateParameter
                                     userInfo:@{WCSErrorKey : errorMsg}];
    return [WCSTask taskWithError:error];
  }
  
  return nil;
}

@end
