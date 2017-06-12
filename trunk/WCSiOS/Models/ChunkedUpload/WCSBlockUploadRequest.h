//
//  WCSMakeFileRequest.h
//  WCSiOS
//
//  Created by mato on 16/4/25.
//  Copyright © 2016年 CNC. All rights reserved.
//

#import "WCSModel.h"

@interface WCSBlockUploadRequest : WCSModel<WCSRequestModelSerializer>

// 要上传的文件的URL（必填）
@property (nonatomic, copy, nonnull) NSURL *fileURL;

// 分片上传的凭证（必填）
@property (nonatomic, copy, nonnull) NSString *uploadToken;

// 上传到云端的文件名（可为空）
@property (nonatomic, copy, nullable) NSString *fileKey;

// 文件的mime类型（可为空）
@property (nonatomic, copy, nullable) NSString *mimeType;

// 自定义参数参数的值，当token有指定自定义参数时使用。（可为空）
@property (nonatomic, strong, nullable) NSDictionary *customParams;

// 设置片的大小，默认为256KB
// 注意：片的大小必须是64K的倍数，最大不能超过块的大小。
@property (nonatomic, assign) NSUInteger chunkSize;

// 设置块的大小，默认为4M
// 注意：块的大小必须是4M的倍数，最大不能超过100M
@property (nonatomic, assign) NSUInteger blockSize;

/**
 上传的进度，其中如果是网络超时导致重传时，bytesSent的值可能会为负数，用于表示回退之前的进度条，建议直接使用totalBytesSent。

 @param uploadProgress 上传进度的回掉
 */
- (void)setUploadProgress:(void (^ _Nullable )(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend))uploadProgress;

- (NSError * _Nullable)validateRequest;

@end
