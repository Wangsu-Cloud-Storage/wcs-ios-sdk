//
//  WCSMakeBlockRequest.m
//  WCSiOS
//
//  Created by mato on 16/4/21.
//  Copyright © 2016年 CNC. All rights reserved.
//

#import "WCSMakeBlockRequest.h"
#import "WCSMakeBlockResult.h"
#import "NSData+WCSCommonAlgorithm.h"

@implementation WCSMakeBlockRequest

- (instancetype)initWithUploadToken:(NSString *)uploadToken
                               size:(UInt64)size
                              order:(NSUInteger)order
                          blockSize:(UInt64)blockSize
                        chunkedData:(NSData *)chunkedData
                            fileKey:(NSString *)fileKey
                           mimeType:(NSString *)mimeType
                        uploadBatch:(NSString *)uploadBatch{
  if (self = [super init]) {
    _uploadToken = [uploadToken copy];
    _size = size;
    _order = order;
    _chunkedData = [chunkedData copy];
    _fileKey = [fileKey copy];
    _mimeType = [mimeType copy];
    _uploadBatch = [uploadBatch copy];
    _blockSize = blockSize;
  }
  return self;
}

- (WCSTask *)constructSessionTaskUsingSession:(NSURLSession *)session baseURL:(NSURL *)baseURL {
  return [[[WCSTask taskWithResult:nil] continueWithSuccessBlock:^id _Nullable(WCSTask * _Nonnull task) {
    return [self validateRequest];
  }] continueWithSuccessBlock:^id _Nullable(WCSTask * _Nonnull task) {
    NSString *pathFormMakeBlock = [NSString stringWithFormat:@"/mkblk/%@/%tu", @(self.blockSize), self.order];
    NSString *baseURLString = baseURL != nil ? baseURL.absoluteString : WCSBaseUploadString;
    NSString *URLString = [NSString stringWithFormat:@"%@%@", baseURLString, pathFormMakeBlock];
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
  NSString *errorMessage = nil;
  if (!self.uploadToken || self.uploadToken.length == 0) {
    errorMessage = @"Token needed.";
  }
  
  if (errorMessage && (!self.chunkedData || self.chunkedData.length == 0)) {
    errorMessage = @"Chunked not found.";
  }
  
  if (errorMessage) {
    NSError *error = [NSError errorWithDomain:WCSClientErrorDomain
                                         code:WCSClientErrorInvalidateParameter
                                     userInfo:@{WCSErrorKey : errorMessage}];
    return [WCSTask taskWithError:error];
  }
  return nil;
}

@end
