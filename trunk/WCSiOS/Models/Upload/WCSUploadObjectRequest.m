//
//  WCSPutObjectRequest.m
//  WCSiOS
//
//  Created by mato on 16/3/24.
//  Copyright © 2016年 CNC. All rights reserved.
//

#import "WCSLogging.h"
#import "WCSUploadObjectRequest.h"

@implementation WCSUploadObjectRequest

- (WCSTask *)constructSessionTaskUsingSession:(NSURLSession *)session baseURL:(NSURL *)baseURL {
  NSString *baseURLString = baseURL != nil ? baseURL.absoluteString : WCSBaseUploadString;
  NSString *URLString = [NSString stringWithFormat:@"%@%@", baseURLString, WCSPathForPut];
  return [[[WCSTask taskWithResult:nil] continueWithSuccessBlock:^id _Nullable(WCSTask * _Nonnull task) {
    return [self validateRequest];
  }] continueWithSuccessBlock:^id _Nullable(WCSTask * _Nonnull task) {
    [self resetData];
    [self addPostValue:self.token forKey:WCSFormToken];
    if(self.key) {
      [self addPostValue:self.key forKey:WCSFormUploadFileKey];
    }
    [self.customParams enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
      if([key isKindOfClass:[NSString class]]){
        [self addPostValue:obj forKey:key];
      }
    }];
    
    if (self.fileData) {
      [self addFileData:self.fileData fileName:self.fileName mimeType:self.mimeType ? : @"application/octet-stream"];
    } else {
      [self addFileURL:self.fileURL fileName:self.fileName mimeType:self.mimeType];
    }
    NSString *boundary = [[self class] createMultipartFormBoundary];
    NSData *bodyData = [self buildMultipartFormDataPostBodyUsingBoundary:boundary];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:URLString]];
    request.HTTPMethod = [NSString wcs_stringWithHTTPMethod:WCSHTTPMethodPOST];
    request.HTTPBody = bodyData;
    [request setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary] forHTTPHeaderField:@"Content-Type"];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request];
    
    return [WCSTask taskWithResult:dataTask];
  }];
}

- (WCSTask *)validateRequest {
  NSString *errorMessage = nil;
  if (!self.fileData && !self.fileURL) {
    errorMessage = @"Data not found for upload";
  }
  
  if (!errorMessage && (!self.fileData && ![[NSFileManager defaultManager] fileExistsAtPath:[self.fileURL path]])) {
    errorMessage = @"File not found at fileURL";
  }
  
  if (!errorMessage && (!self.fileName || self.fileName.length == 0)) {
    errorMessage = @"fileName needed.";
  }
  
  if (!errorMessage && (!self.token || self.token.length == 0)) {
    errorMessage = @"token needed.";
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
