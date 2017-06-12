//
//  WCSChunkCache.h
//  WCS-SDK
//
//  Created by mato on 16/1/14.
//  Copyright © 2016年 WCS. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WCSChunkCache : NSObject

@property (nonatomic, copy) NSString *fileHash;
@property (nonatomic, copy) NSString *uploadBatch;
@property (nonatomic, assign) NSUInteger blockSize;
@property (nonatomic, assign) NSUInteger chunkSize;

+ (WCSChunkCache *)chunkCacheFromFileMD5:(NSString *)fileMD5
                                   token:(NSString *)token
                                 fileKey:(NSString *)fileKey
                              blockArray:(NSArray*)blockArray;

- (UInt64)uploadedSizeInBlockArray:(NSArray *)blockArray;

- (void)setContext:(NSString *)context uploadedIndex:(NSInteger)uploadedIndex atBlockIndex:(NSInteger)blockIndex;

- (NSMutableArray *)blockContextArray;

@end
