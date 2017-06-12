//
//  WCSMakeBlockResult.h
//  WCSiOS
//
//  Created by mato on 16/4/25.
//  Copyright © 2016年 CNC. All rights reserved.
//

#import "WCSModel.h"

@interface WCSMakeBlockResult : WCSModel<WCSResponseModelSerializer>

@property (nonatomic, copy, readonly) NSString *context;
@property (nonatomic, copy, readonly) NSString *checksum;
@property (nonatomic, assign, readonly) NSInteger crc32;
@property (nonatomic, assign, readonly) UInt64 offset;

- (instancetype)initWithResponseData:(NSData *)data HTTPResponse:(NSHTTPURLResponse *)response error:(NSError *__autoreleasing *)error;

@end
