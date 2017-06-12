//
//  WCSFormRequest.h
//  WCSiOS
//
//  Created by mato on 16/4/7.
//  Copyright © 2016年 CNC. All rights reserved.
//

#import "WCSModel.h"
#import "WCSNetworking.h"

typedef NS_ENUM(NSInteger, WCSPostFormat) {
  WCSPostFormatURLEncoded = 0,
  WCSPostFormatMultipartForm = 1
};

@interface WCSFormRequest : WCSModel

@property (nonatomic, strong, nullable) NSDictionary *customHTTPHeaders;

+ (NSString * _Nonnull)createMultipartFormBoundary;

// 超时重试时，需要清空原来的表单数据。
- (void)resetData;

- (NSMutableData * _Nonnull)buildMultipartFormDataPostBodyUsingBoundary:(NSString * _Nonnull)boundary;

- (void)addPostValue:(NSString * _Nonnull)postValue forKey:(NSString * _Nonnull)key;

- (void)addFileData:(NSData * _Nonnull)fileData fileName:(NSString * _Nonnull)fileName mimeType:(NSString * _Nonnull)mimeType;

- (void)addFileData:(NSData * _Nonnull)fileData fileName:(NSString * _Nonnull)fileName;

- (void)addFileURL:(NSURL * _Nonnull)fileURL fileName:(NSString * _Nonnull)fileName mimeType:(NSString * _Nonnull)mimeType;

- (void)addFileURL:(NSURL * _Nonnull)fileURL fileName:(NSString * _Nonnull)fileName;

- (void)addFileURL:(NSURL * _Nonnull)fileURL;

@end
