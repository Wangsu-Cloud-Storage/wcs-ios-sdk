//
//  WCSWCSPutObjectResult.h
//  WCSiOS
//
//  Created by mato on 16/3/25.
//  Copyright © 2016年 CNC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WCSNetworking.h"
#import "WCSModel.h"

@interface WCSUploadObjectResult : WCSModel<WCSResponseModelSerializer>

// 根据token返回的值（可能包含returnBody、customBody的值，格式为JSON）
@property (nonatomic, strong, nullable) NSDictionary *results;

@end
