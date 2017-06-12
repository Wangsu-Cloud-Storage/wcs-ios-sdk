//
//  WCSThreadSafeMutableDictionary.m
//  WCSiOS
//
//  Created by mato on 16/3/24.
//  Copyright © 2016年 CNC. All rights reserved.
//

#import "WCSThreadSafeMutableDictionary.h"
#import <libkern/OSAtomic.h>

#define LOCKED(...) dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER); \
__VA_ARGS__; \
dispatch_semaphore_signal(_lock);

@interface WCSThreadSafeMutableDictionary()

@property (nonatomic, strong) dispatch_semaphore_t lock;
@property (nonatomic, strong) NSMutableDictionary *dictionary;

@end

@implementation WCSThreadSafeMutableDictionary

- (id)init {
  if (self = [super init]) {
    _dictionary = [[NSMutableDictionary alloc] initWithCapacity:0];
    _lock = dispatch_semaphore_create(1);
  }
  return self;
}

- (id)initWithObjects:(NSArray *)objects forKeys:(NSArray *)keys {
  if (self = [self initWithCapacity:objects.count]) {
    [objects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      _dictionary[keys[idx]] = obj;
    }];
  }
  return self;
}

- (id)initWithCapacity:(NSUInteger)capacity {
  if ((self = [super init])) {
    _dictionary = [[NSMutableDictionary alloc] initWithCapacity:capacity];
    _lock = dispatch_semaphore_create(1);
  }
  return self;
}

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - NSMutableDictionary

- (void)setObject:(id)anObject forKey:(id<NSCopying>)aKey {
  LOCKED(_dictionary[aKey] = anObject)
}

- (void)addEntriesFromDictionary:(NSDictionary *)otherDictionary {
  LOCKED([_dictionary addEntriesFromDictionary:otherDictionary]);
}

- (void)removeObjectForKey:(id)aKey {
  LOCKED([_dictionary removeObjectForKey:aKey])
}

- (void)removeAllObjects {
  LOCKED([_dictionary removeAllObjects]);
}

- (NSUInteger)count {
  LOCKED(NSUInteger count = _dictionary.count)
  return count;
}

- (NSArray *)allKeys {
  LOCKED(NSArray *allKeys = _dictionary.allKeys)
  return allKeys;
}

- (NSArray *)allValues {
  LOCKED(NSArray *allValues = _dictionary.allValues)
  return allValues;
}

- (id)objectForKey:(id)aKey {
  LOCKED(id obj = _dictionary[aKey])
  return obj;
}

- (id)copyWithZone:(NSZone *)zone {
  return [self mutableCopyWithZone:zone];
}

- (id)mutableCopyWithZone:(NSZone *)zone {
  LOCKED(id copiedDictionary = [[self.class allocWithZone:zone] initWithDictionary:_dictionary])
  return copiedDictionary;
}

- (void)performLockedWithDictionary:(void (^)(NSDictionary *dictionary))block {
  if (block) {
    LOCKED(block(_dictionary));
  }
}

- (BOOL)isEqual:(id)object {
  if (object == self) return YES;
  
  if ([object isKindOfClass:WCSThreadSafeMutableDictionary.class]) {
    WCSThreadSafeMutableDictionary *other = object;
    __block BOOL isEqual = NO;
    [other performLockedWithDictionary:^(NSDictionary *dictionary) {
      [self performLockedWithDictionary:^(NSDictionary *otherDictionary) {
        isEqual = [dictionary isEqual:otherDictionary];
      }];
    }];
    return isEqual;
  }
  return NO;
}

@end