//
//  WCSMultipleUploadRequest.h
//  WCSiOS
//
//  Created by mato on 16/3/30.
//  Copyright © 2016年 CNC. All rights reserved.
//

#import "WCSFormRequest.h"

@interface WCSBatchUploadRequest : WCSFormRequest

// 多文件上传的凭证
@property (nonatomic, strong, readonly, nonnull) NSString *token;

// 自定义参数参数的值，当token有指定自定义参数时使用。
@property (nonatomic, strong, readonly, nullable) NSDictionary *customParams;

- (instancetype _Nonnull)initWithToken:(NSString * _Nonnull)token
                 customParams:(NSDictionary * _Nullable)customParams;

/** 用于添加文件的接口
- (void)addPostValue:(NSString *)postValue forKey:(NSString *)key;

- (void)addFileData:(NSData *)fileData fileName:(NSString *)fileName mimeType:(NSString *)mimeType;

- (void)addFileData:(NSData *)fileData fileName:(NSString *)fileName;

- (void)addFileURL:(NSURL *)fileURL fileName:(NSString *)fileName mimeType:(NSString *)mimeType;

- (void)addFileURL:(NSURL *)fileURL fileName:(NSString *)fileName;

- (void)addFileURL:(NSURL *)fileURL;
 */

@end
