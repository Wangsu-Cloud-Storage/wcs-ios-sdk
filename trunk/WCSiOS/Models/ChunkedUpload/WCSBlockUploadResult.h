//
//  WCSMakeFileResult.h
//  WCSiOS
//
//  Created by mato on 16/4/26.
//  Copyright © 2016年 CNC. All rights reserved.
//

#import "WCSModel.h"

@interface WCSBlockUploadResult : WCSModel<WCSResponseModelSerializer>

// 根据token返回的值（可能包含returnBody、customBody的值，格式为JSON）
@property (nonatomic, strong) NSDictionary *results;

@end
