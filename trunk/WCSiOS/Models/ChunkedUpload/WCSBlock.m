//
//  WCSBlock.m
//  WCSSDK
//
//  Created by mato on 14-11-19.
//  Copyright (c) 2014年 wcs. All rights reserved.
//

#import "WCSBlock.h"
#import "WCSLogging.h"

const UInt64 kWCSDefualtBlockSize = 4 * 1024 * 1024;
const UInt64 kWCSDefaultChunkSize = 256 * 1024;
const UInt64 kWCSMinBlockSize = kWCSDefualtBlockSize;
const UInt64 kWCSMaxBlockSize = 100 * 1024 * 1024;
const UInt64 kWCSMinChunkSize = 64 * 1024;
const UInt64 kWCSMaxChunkSize = kWCSDefualtBlockSize;

@interface WCSBlock()

@property (nonatomic, strong) NSFileHandle* fileHandle;

@end

@implementation WCSBlock

+ (NSArray*)blocksFromFilePath:(NSString*)filePath
                     blockSize:(UInt64)blockSize
                     chunkSize:(NSUInteger)chunkSize {
  UInt64 fileSize = 0;
  NSError *error = nil;
  NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:&error];
  if(!error){
    fileSize = (UInt64)[attributes fileSize];
  }
  UInt64 defaultBlockSize = kWCSDefualtBlockSize;
  if ((blockSize % kWCSMinBlockSize) == 0) {
    defaultBlockSize = blockSize;
  }
  UInt64 realChunkSize = kWCSDefaultChunkSize;
  if ((chunkSize % kWCSMinChunkSize == 0)) {
    realChunkSize = chunkSize;
  }
  WCSLogDebug("file size : %@, default block size : %@", @(fileSize), @(defaultBlockSize));
  NSUInteger blockCount = (NSUInteger)((fileSize + defaultBlockSize - 1) / defaultBlockSize);
  NSMutableArray* blockArray = [NSMutableArray array];
  for (int i = 0 ; i < blockCount; i++) {
    UInt64 realBlockSize = defaultBlockSize;
    // (i + 1) is last block
    if(i + 1 == blockCount){
      UInt64 remain = fileSize % defaultBlockSize;
      realBlockSize = remain == 0 ? defaultBlockSize : remain;
    }
    
    WCSBlock* block = [[WCSBlock alloc] initWithFilePath:filePath
                                             startOffset:(defaultBlockSize * i)
                                                fileSize:fileSize
                                               blockSize:realBlockSize
                                               chunkSize:realChunkSize
                                              blockIndex:i];
    [blockArray addObject:block];
  }
  return [NSArray arrayWithArray:blockArray];
}

- (instancetype)initWithFilePath:(NSString*)filePath
                     startOffset:(UInt64)startOffset
                        fileSize:(UInt64)fileSize
                       blockSize:(UInt64)blockSize
                       chunkSize:(NSUInteger)chunkSize
                      blockIndex:(NSUInteger)blockIndex{
  if(self = [super init]){
    self.startOffset = startOffset;
    self.fileSize = fileSize;
    self.size = blockSize;
    self.chunkSize = chunkSize;
    self.fileHandle = [NSFileHandle fileHandleForReadingAtPath:filePath];
    self.blockIndex = blockIndex;
  }
  return self;
}

- (NSData*)moveToNextChunk {
  NSData *chunkData = [self chunkOnIndex:self.currentChunkIndex];
  if (chunkData) {
    self.currentChunkIndex += 1;
  }
  return chunkData;
}

- (NSData*)lastChunk {
  return [self chunkOnIndex:(self.currentChunkIndex - 1)];
}

- (NSData*)chunkOnIndex:(NSUInteger)index{
  if(index * self.chunkSize >= self.size){
    return nil;
  }
  UInt64 currentOffset = self.startOffset + ((UInt64)index * (UInt64)self.chunkSize);
  UInt64 chunkSize = self.chunkSize;
  // current chunk size less than kChunkSize
  if((currentOffset + self.chunkSize) > (self.startOffset + self.size)){
    chunkSize = (UInt64)(self.size % self.chunkSize);
  }
  WCSLogDebug(@"%@ start offset is %@, chunk size : %@, current index : %@", @(self.hash), @(self.startOffset), @(chunkSize), @(index));
  [self.fileHandle seekToFileOffset:currentOffset];
  return [self.fileHandle readDataOfLength:chunkSize];
}

@end
