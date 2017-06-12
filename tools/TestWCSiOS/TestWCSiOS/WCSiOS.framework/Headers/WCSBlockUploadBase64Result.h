//
//  WCSBlockUploadBase64Result.h
//  TestWCSiOS
//
//  Created by mato on 2016/11/18.
//  Copyright © 2016年 CNC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WCSBlockUploadBase64Result : NSObject

// 根据token返回的值（可能包含returnBody、customBody的值，格式为base64编码后的JSON字符串）
@property (nonatomic, copy) NSString *resultString;

- (instancetype)initWithJSONDiction:(NSDictionary *)JSONDictionary;

@end
