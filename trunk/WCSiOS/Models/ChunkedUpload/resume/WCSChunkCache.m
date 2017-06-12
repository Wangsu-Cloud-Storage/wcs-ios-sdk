//
//  WCSSliceCache.m
//  WCS-SDK
//
//  Created by mato on 16/1/14.
//  Copyright © 2016年 WCS. All rights reserved.
//

#import "WCSChunkCache.h"
#import "WCSBlock.h"
#import "WCSGTMStringEncoding.h"
#import "WCSChunkCacheManager.h"
#import "NSDictionary+WCSDictionarySafeExtensions.h"

@interface WCSChunkCache()

@property (nonatomic, strong) NSMutableArray* uploadedIndexArray;
@property (nonatomic, strong) NSMutableArray* blockContextArray;
@property (nonatomic, strong) dispatch_semaphore_t lock;

@end

@implementation WCSChunkCache

- (instancetype)init{
  if(self = [super init]){
    _uploadedIndexArray = [NSMutableArray array];
    _blockContextArray = [NSMutableArray array];
    _lock = dispatch_semaphore_create(1);
  }
  return self;
}

+ (WCSChunkCache *)chunkCacheFromFileMD5:(NSString *)fileMD5
                                   token:(NSString *)token
                                 fileKey:(NSString *)fileKey
                              blockArray:(NSArray*)blockArray {
  NSMutableString *fileHash = [NSMutableString stringWithFormat:@"%@:%@", fileMD5, [self scopeFromToken:token]];
  if (fileKey) {
    [fileHash appendFormat:@":%@", fileKey];
  }
  
  WCSChunkCache *chunkCache = [[WCSChunkCacheManager sharedInstance] getChunkCache:fileHash];
  UInt64 chunkSize = ((WCSBlock *)blockArray[0]).chunkSize;
  UInt64 blockSize = ((WCSBlock *)blockArray[0]).size;
  BOOL isChunkConfigChanged = (chunkCache.chunkSize != chunkSize || chunkCache.blockSize != blockSize);
  if(!chunkCache || blockArray.count != chunkCache.uploadedIndexArray.count || isChunkConfigChanged){
    chunkCache = [[WCSChunkCache alloc] init];
    chunkCache.fileHash = fileHash;
    chunkCache.uploadBatch = [[NSUUID UUID] UUIDString];
    chunkCache.chunkSize = chunkSize;
    chunkCache.blockSize = blockSize;
    for (int i = 0; i < blockArray.count; i++) {
      [chunkCache.uploadedIndexArray insertObject:@0 atIndex:i];
      [chunkCache.blockContextArray insertObject:@"" atIndex:i];
    }
  }
  return chunkCache;
}

- (UInt64)uploadedSizeInBlockArray:(NSArray *)blockArray {
  UInt64 uploadedSize = 0;
  dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
  for (int i = 0; i < self.uploadedIndexArray.count; i++) {
    NSNumber *cacheIndexNumber = [self.uploadedIndexArray objectAtIndex:i];
    NSInteger uploadingIndexValue = cacheIndexNumber ? [cacheIndexNumber integerValue] : 0;
    WCSBlock* block = [blockArray objectAtIndex:i];
    uploadedSize += uploadingIndexValue * block.chunkSize;
    block.currentChunkIndex = uploadingIndexValue;
  }
  dispatch_semaphore_signal(_lock);
  return uploadedSize;
}

- (void)setContext:(NSString *)context uploadedIndex:(NSInteger)uploadedIndex atBlockIndex:(NSInteger)blockIndex {
  dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
  [_blockContextArray replaceObjectAtIndex:blockIndex withObject:context];
  [_uploadedIndexArray replaceObjectAtIndex:blockIndex withObject:@(uploadedIndex)];
  dispatch_semaphore_signal(_lock);
}

- (NSMutableArray *)blockContextArray {
  NSMutableArray *array = nil;
  dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
  array = _blockContextArray;
  dispatch_semaphore_signal(_lock);
  return array;
}

- (NSString *) description {
  return [NSString stringWithFormat:@"WCSChunkCache<%@, %@, %@, %@, %@>", self.fileHash,
          self.uploadedIndexArray, self.blockContextArray, @(self.blockSize), @(self.chunkSize)];
}

+ (NSString*)scopeFromToken:(NSString*)token {
  NSArray* uploadTokenArray = [token componentsSeparatedByString:@":"];
  if(uploadTokenArray.count != 3){
    return @"";
  }
  NSString* policyJsonString = [[WCSGTMStringEncoding rfc4648Base64WebsafeStringEncoding] stringByDecoding:[uploadTokenArray objectAtIndex:2]];
  NSDictionary* policyJSON = [NSJSONSerialization JSONObjectWithData:[policyJsonString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
  return [policyJSON safeStringForKey:@"scope"];
}

@end
