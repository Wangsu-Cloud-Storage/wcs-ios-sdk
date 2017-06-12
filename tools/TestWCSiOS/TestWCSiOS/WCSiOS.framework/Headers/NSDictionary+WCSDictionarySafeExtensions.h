//
//  NSDictionary+WCSDictionarySafeExtensions.h
//  WCS
//
//  Created by mato on 14-8-22.
//  Copyright (c) 2014年 DFP. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CoreGraphics/CGBase.h"

@interface NSDictionary (WCSDictionarySafeExtensions)

- (id)valueForKey:(NSString *)key defaultsTo:(id)defaultValue;
- (id)valueForKeyPath:(NSString *)keyPath defaultsTo:(id)defaultValue;

- (BOOL)safeBoolForKey:(NSString *)key;
- (BOOL)safeBoolForKeyPath:(NSString *)keyPath;

- (NSInteger)safeIntegerForKey:(NSString *)key;
- (NSInteger)safeIntegerForKeyPath:(NSString *)keyPath;

- (double)safeDoubleForKey:(NSString*)key;
- (double)safeDoubleForKeyPath:(NSString *)keyPath;

- (CGFloat)safeFloatForKey:(NSString*)key;
- (CGFloat)safeFloatForKeyPath:(NSString *)keyPath;

- (long)safeLongForKey:(NSString*)key;
- (long)safeLongForKeyPath:(NSString *)keyPath;

- (long long)safeLongLongForKey:(NSString*)key;
- (long long)safeLongLongForKeyPath:(NSString *)keyPath;

- (NSDictionary *)safeDictForKey:(NSString *)key;
- (NSDictionary *)safeDictForKeyPath:(NSString *)keyPath;

- (NSString *)safeStringForKey:(NSString *)key;
- (NSString *)safeStringForKeyPath:(NSString *)keyPath;

- (NSArray *)safeArrayForKey:(NSString *)key;
- (NSArray *)safeArrayForKeyPath:(NSString *)keyPath;

- (NSDate *)safeDateForKey:(NSString *)key;
- (NSDate *)safeDateForKeyPath:(NSString *)keyPath;

- (NSURL *)safeURLForKey:(NSString *)key;
- (NSURL *)safeURLForKeyPath:(NSString *)keyPath;

@end
