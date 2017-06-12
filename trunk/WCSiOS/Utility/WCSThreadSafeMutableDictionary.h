//
//  WCSThreadSafeMutableDictionary.h
//  WCSiOS
//
//  Created by mato on 16/3/24.
//  Copyright © 2016年 CNC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WCSThreadSafeMutableDictionary : NSObject<NSCopying, NSMutableCopying>

- (id)initWithObjects:(NSArray *)objects forKeys:(NSArray *)keys;

- (id)initWithCapacity:(NSUInteger)capacity;

- (void)setObject:(id)anObject forKey:(id<NSCopying>)aKey;

- (void)addEntriesFromDictionary:(NSDictionary *)otherDictionary;

- (void)removeObjectForKey:(id)aKey;

- (void)removeAllObjects;

- (NSUInteger)count;

- (NSArray *)allKeys;

- (NSArray *)allValues;

- (id)objectForKey:(id)aKey;

- (BOOL)isEqual:(id)object;

@end
