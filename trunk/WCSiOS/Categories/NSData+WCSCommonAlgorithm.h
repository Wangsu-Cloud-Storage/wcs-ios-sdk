//
//  NSData+WCSCommonAlgorithm.h
//  WCS-SDK
//
//  Created by mato on 14-11-24.
//  Copyright (c) 2014年 WCS. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (WCSCommonAlgorithm)

// TODO:optimize without reading all data.
- (NSString *)wetag;

- (UInt32)commonCrc32;

@end
