//
//  WCSUploadChunkResult.h
//  WCSiOS
//
//  Created by mato on 16/4/25.
//  Copyright © 2016年 CNC. All rights reserved.
//

#import "WCSModel.h"

@interface WCSUploadChunkResult : WCSModel<WCSResponseModelSerializer>

@property (nonatomic, copy) NSString *context;
@property (nonatomic, copy) NSString *checksum;
@property (nonatomic, assign) NSInteger crc32;
@property (nonatomic, assign) UInt64 offset;

- (instancetype)initWithResponseData:(NSData *)data HTTPResponse:(NSHTTPURLResponse *)response error:(NSError *__autoreleasing *)error;

@end
