//
//  WCSApi.h
//  WCSiOS
//
//  Created by mato on 16/5/5.
//  Copyright © 2016年 CNC. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  兼容1.x版本，推荐使用WCSClient
 */
@interface WCSApi : NSObject

/**
 *  配置上传的服务器，务必在调用上传任务之前配置
 *
 *  @param uploadUrl 需要上传到的服务器
 */
+ (void)configUploadUrl:(NSString *)uploadUrl;

/**
 *  取消上传任务
 *
 *  @param tag 任务标记
 */
+ (void)cancelUploadingOperationInTag:(NSUInteger)tag;

/**
 *  上传文件到网宿云存储
 *
 *  @param uploadToken   上传文件所需要的凭证
 *  @param fileData      要上传的文件二进制数据
 *  @param fileName      文件名称
 *  @param mimeType      文件类型
 *  @param taskTag       上传任务的tag，配合cancelUploadingOperationInTag:使用
 *  @param callbackBody  自定义参数及callbackBody
 *  @param successBlock  上传成功后回调的block
 *  @param progressBlock 上传过程中的进度条
 *  @param failuredBlock 上传失败后回调的block
 */
+ (void)uploadFileWithUploadToken:(NSString *)uploadToken
                         fileData:(NSData *)fileData
                        fileNamed:(NSString *)fileName
                     fileMimeType:(NSString *)mimeType
                          taskTag:(NSUInteger)taskTag
                     callbackBody:(NSDictionary *)callbackBody
                usingSuccessBlock:(void(^)(NSInteger statusCode, NSDictionary* response))successBlock
                    progressBlock:(void(^)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))progressBlock
                    failuredBlock:(void(^)(NSInteger statusCode, NSDictionary* errorMsg))failuredBlock;

/**
 *  切片上传到网宿云存储，默认每一块大小为4M
 *
 *  @param filePath      文件路径
 *  @param uploadToken   上传token
 *  @param progressBlock 上传进度
 *  @param taskTag       上传任务的tag，配合cancelUploadingOperationInTag:使用
 *  @param callbackBody  自定义参数及callbackBody
 *  @param successBlock  成功回调
 *  @param failuredBlock 失败回调
 */
+ (void)sliceUploadFile:(NSString *)filePath
                  token:(NSString *)uploadToken
                taskTag:(NSUInteger)taskTag
           callbackBody:(NSDictionary *)callbackBody
          progressBlock:(void(^)(long long totalBytesWritten, long long totalBytesExpectedToWrite))progressBlock
           successBlock:(void(^)(NSDictionary *responseDict))successBlock
          failuredBlock:(void(^)(NSDictionary *errorMsg))failuredBlock;

@end
