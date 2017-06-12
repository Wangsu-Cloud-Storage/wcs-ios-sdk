//
//  WCSBlock.h
//  WCSSDK
//
//  Created by mato on 14-11-19.
//  Copyright (c) 2014年 wcs. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT const UInt64 kWCSDefualtBlockSize;
FOUNDATION_EXPORT const UInt64 kWCSDefaultChunkSize;
FOUNDATION_EXPORT const UInt64 kWCSMinBlockSize;
FOUNDATION_EXPORT const UInt64 kWCSMaxBlockSize;
FOUNDATION_EXPORT const UInt64 kWCSMinChunkSize;
FOUNDATION_EXPORT const UInt64 kWCSMaxChunkSize;

@interface WCSBlock : NSObject

@property (nonatomic, assign) UInt64 startOffset;
@property (nonatomic, assign) UInt64 size;
@property (nonatomic, assign) NSUInteger chunkSize;
@property (nonatomic, assign) NSUInteger currentChunkIndex;
@property (nonatomic, assign) UInt64 fileSize;
@property (nonatomic, assign) NSUInteger blockIndex;

+ (NSArray*)blocksFromFilePath:(NSString*)filePath
                     blockSize:(UInt64)blockSize
                     chunkSize:(NSUInteger)chunkSize;

- (instancetype)initWithFilePath:(NSString*)filePath
                     startOffset:(UInt64)startOffset
                        fileSize:(UInt64)fileSize
                       blockSize:(UInt64)blockSize
                       chunkSize:(NSUInteger)chunkSize
                      blockIndex:(NSUInteger)blockIndex;

- (NSData*)moveToNextChunk;

@end
