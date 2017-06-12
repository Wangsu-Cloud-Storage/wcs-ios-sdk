//
//  WCSPutObjectRequest.h
//  WCSiOS
//
//  Created by mato on 16/3/24.
//  Copyright © 2016年 CNC. All rights reserved.
//

#import "WCSFormRequest.h"

@interface WCSUploadObjectRequest : WCSFormRequest

// 上传的token（必填）
@property (nonatomic, copy, nonnull) NSString *token;

// 文件名（比填）
@property (nonatomic, copy, nonnull) NSString *fileName;

// 文件的数据（fileData与fileURL必须有一个有值，两者都有值则以fileData优先）
@property (nonatomic, copy, nullable) NSData *fileData;

// 文件的URL路径（fileData与fileURL必须有一个有值，两者都有值则以fileData优先）
@property (nonatomic, copy, nullable) NSURL *fileURL;

// 上传到云端的文件名（可为空）
@property (nonatomic, copy, nullable) NSString *key;

// 文件的mime类型（可为空）
@property (nonatomic, copy, nullable) NSString *mimeType;

// 自定义参数参数的值，当token有指定自定义参数时使用。（可为空）
@property (nonatomic, strong, nullable) NSDictionary *customParams;

@end
