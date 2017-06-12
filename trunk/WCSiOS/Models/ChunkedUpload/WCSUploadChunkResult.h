//
//  WCSUploadChunkResult.h
//  WCSiOS
//
//  Created by mato on 16/4/25.
//  Copyright © 2016年 CNC. All rights reserved.
//

#import "WCSModel.h"

@interface WCSUploadChunkResult : WCSModel<WCSResponseModelSerializer>

@property (nonatomic, copy) NSString *context;//本次上传成功后的块级上传控制信息，用于后续上传片及生成文件。本字段是只能被WCS服务器解读使用的不透明字段，上传端不应修改其内容。每次返回的<ctx>都只对应紧随其后的下一个上传数据片，上传非对应数据片会返回401状态码。
@property (nonatomic, copy) NSString *checksum;//上传块校验码。
@property (nonatomic, assign) NSInteger crc32;//上传块Crc32，客户可通过此字段对上传块的完整性进行较验。
@property (nonatomic, assign) UInt64 offset;//下一个上传片在切割块中的偏移。若片大小与块大小相等，则该返回值为该块的大小。

- (instancetype)initWithResponseData:(NSData *)data HTTPResponse:(NSHTTPURLResponse *)response error:(NSError *__autoreleasing *)error;

@end
