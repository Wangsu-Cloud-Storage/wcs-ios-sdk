//
//  WCSSliceCacheManager.m
//  WCS-SDK
//
//  Created by mato on 16/1/14.
//  Copyright © 2016年 WCS. All rights reserved.
//

#import "WCSChunkCacheManager.h"
#import "WCSLogging.h"

@interface WCSChunkCacheManager()

@property (nonatomic, strong) NSMutableDictionary *sliceCacheDict;

@end

@implementation WCSChunkCacheManager

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static WCSChunkCacheManager *sSliceCacheManager;
    dispatch_once(&onceToken, ^{
        sSliceCacheManager = [[WCSChunkCacheManager alloc] init];
    });
    return sSliceCacheManager;
}

- (instancetype)init {
    if (self = [super init]) {
        self.sliceCacheDict = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)addChunkCache:(WCSChunkCache *)sliceCache {
    @synchronized(self) {
        if (!sliceCache || !sliceCache.fileHash || sliceCache.fileHash.length == 0) {
            return;
        }
                
        __block BOOL exists = NO;
        [self.sliceCacheDict enumerateKeysAndObjectsUsingBlock:^(NSString *_Nonnull key, WCSChunkCache * _Nonnull obj, BOOL * _Nonnull stop) {
            exists = [key isEqualToString:sliceCache.fileHash];
        }];
        if (exists) {
            return;
        }
        
        [self.sliceCacheDict setObject:sliceCache forKey:sliceCache.fileHash];
    }
}

- (WCSChunkCache *)getChunkCache:(NSString *)fileHash {
    @synchronized(self) {
        if (fileHash && fileHash.length != 0) {
            return [self.sliceCacheDict objectForKey:fileHash];
        }
        return nil;
    }
}

- (void)removeChunkCache:(NSString *)fileHash {
    @synchronized(self) {
        if (fileHash && fileHash.length != 0) {
            [self.sliceCacheDict removeObjectForKey:fileHash];
        }
    }
}

- (void)dump {
    if (self.sliceCacheDict.count != 0) {
        [self.sliceCacheDict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            WCSLogDebug("WCSSliceCache : %@", obj);
        }];
    } else {
        WCSLogDebug("WCSSliceCache : NULL");
    }
}

@end
