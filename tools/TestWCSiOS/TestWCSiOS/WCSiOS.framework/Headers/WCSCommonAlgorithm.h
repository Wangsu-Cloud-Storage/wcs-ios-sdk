//
//  WCSCommonAlgorithm.h
//  WCSiOS
//
//  Created by mato on 16/4/28.
//  Copyright © 2016年 CNC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WCSCommonAlgorithm : NSObject

// 内存泄露，需要使用时候在while里面添加@autorelease并测试。
// 详见:http://stackoverflow.com/questions/10989164/huge-memory-footprint-with-arc
+ (unsigned char *)MD5AtFilePath:(NSString *)filePath;
+ (NSString *)MD5StringAtFilePath:(NSString *)filePath;
+ (NSString *)MD5StringFromString:(NSString *)originalString;

+ (NSString *)webSafeBase64EncodedString:(NSString *)string;
+ (NSString *)base64EncodedString:(NSString *)string;

@end
