//
//  WCSMakeBlockRequest.h
//  WCSiOS
//
//  Created by mato on 16/4/21.
//  Copyright © 2016年 CNC. All rights reserved.
//

#import "WCSModel.h"

@interface WCSMakeBlockRequest : WCSModel

@property (nonatomic, copy) NSString *uploadToken;
@property (nonatomic, assign) UInt64 size;
@property (nonatomic, assign) NSUInteger order;
@property (nonatomic, copy) NSData *chunkedData;
@property (nonatomic, copy) NSString *fileKey;
@property (nonatomic, copy) NSString *mimeType;
@property (nonatomic, copy) NSString *uploadBatch;
@property (nonatomic, assign) UInt64 blockSize;

- (instancetype)initWithUploadToken:(NSString *)uploadToken
                               size:(UInt64)size
                              order:(NSUInteger)order
                          blockSize:(UInt64)blockSize
                        chunkedData:(NSData *)chunkedData
                            fileKey:(NSString *)fileKey
                           mimeType:(NSString *)mimeType
                        uploadBatch:(NSString *)uploadBatch;

@end
