//
//  WCSSliceCacheManager.h
//  WCS-SDK
//
//  Created by mato on 16/1/14.
//  Copyright © 2016年 WCS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WCSChunkCache.h"

@interface WCSChunkCacheManager : NSObject

+ (instancetype)sharedInstance;

- (void)addChunkCache:(WCSChunkCache *)sliceCache;

- (WCSChunkCache *)getChunkCache:(NSString *)fileHash;

- (void)removeChunkCache:(NSString *)fileHash;

- (void)dump;

@end
