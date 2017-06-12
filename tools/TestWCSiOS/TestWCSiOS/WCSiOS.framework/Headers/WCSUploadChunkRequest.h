//
//  WCSUploadChunkRequest.h
//  WCSiOS
//
//  Created by mato on 16/4/25.
//  Copyright © 2016年 CNC. All rights reserved.
//

#import "WCSModel.h"

@interface WCSUploadChunkRequest : WCSModel<WCSRequestModelSerializer>

@property (nonatomic, copy) NSString *lastContext;
@property (nonatomic, assign) UInt64 offset;
@property (nonatomic, copy) NSString *uploadToken;
@property (nonatomic, copy) NSData *chunkedData;

@property (nonatomic, copy) NSString *fileKey;
@property (nonatomic, copy) NSString *mimeType;
@property (nonatomic, copy) NSString *uploadBatch;

- (instancetype)initWithOffset:(UInt64)offset
                   lastContext:(NSString *)lastContext
                   uploadToken:(NSString *)uploadToken
                   chunkedData:(NSData *)chunkedData
                       fileKey:(NSString *)fileKey
                      mimeType:(NSString *)mimeType
                   uploadBatch:(NSString *)uploadBatch;

@end
