//
//  WCSBatchUploadResult.h
//  WCSiOS
//
//  Created by mato on 16/4/11.
//  Copyright © 2016年 CNC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WCSModel.h"

@interface WCSBatchUploadResult : WCSModel<WCSResponseModelSerializer>

// 成功的个数
@property (nonatomic, readonly) NSInteger successNum;

// 失败的个数
@property (nonatomic, readonly) NSInteger failedNum;

// 详细内容（格式为JSON）
@property (nonatomic, readonly, strong) NSArray *detailArray;

@end
