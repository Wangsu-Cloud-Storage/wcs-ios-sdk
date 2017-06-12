//
//  WCSMultipleUploadRequest.m
//  WCSiOS
//
//  Created by mato on 16/3/30.
//  Copyright © 2016年 CNC. All rights reserved.
//

#import "WCSBatchUploadRequest.h"

@interface WCSBatchUploadRequest()

@property (nonatomic, strong) NSString *token;
@property (nonatomic, strong) NSDictionary *customParams;

@property (nonatomic, strong) NSMutableArray *fileDataArray;

@end

@implementation WCSBatchUploadRequest

- (instancetype)init {
  @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                 reason:@"`- init` is not a valid initializer. Use `- initWithToken:customParams:` instead."
                               userInfo:nil];
  return self;
}

- (instancetype)initWithToken:(NSString *)token
                 customParams:(NSDictionary *)customParams {
  if (self = [super init]) {
    _token = token;
    _customParams = customParams;
  }
  return self;
}

- (WCSTask *)constructSessionTaskUsingSession:(NSURLSession *)session baseURL:(NSURL *)baseURL {
  NSString *baseURLString = baseURL != nil ? baseURL.absoluteString : WCSBaseUploadString;
  NSString *URLString = [NSString stringWithFormat:@"%@%@", baseURLString, WCSPathForMultipartUpload];
  return [[[WCSTask taskWithResult:nil] continueWithSuccessBlock:^id _Nullable(WCSTask * _Nonnull task) {
    return [self validateRequest];
  }] continueWithSuccessBlock:^id _Nullable(WCSTask * _Nonnull task) {
    [self resetData];
    [self addPostValue:self.token forKey:WCSFormToken];
    [self.customParams enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
      if([key isKindOfClass:[NSString class]]){
        [self addPostValue:obj forKey:key];
      }
    }];
    
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
  if (self.fileDataArray.count == 0) {
    errorMessage = @"Data not found for upload";
  }
  
  if (!errorMessage) {
    for (id fileObj in self.fileDataArray) {
      if ([fileObj isKindOfClass:[NSURL class]]) {
        NSURL *fileURL = fileObj;
        if (![[NSFileManager defaultManager] fileExistsAtPath:[fileURL path]]) {
          errorMessage = [NSString stringWithFormat:@"File not found at %@", fileURL];
        }
      }
    }
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
